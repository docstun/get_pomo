# encoding: utf-8

require File.expand_path("../spec_helper", File.dirname(__FILE__))

include GetPomo
describe GetPomo::PoFile do
  describe :parse do
    it "parses nothing" do
      PoFile.parse("").should be_empty
    end

    it "parses a simple msgid and msgstr" do
      t = PoFile.parse(%Q(msgid "xxx"\nmsgstr "yyy"))
      t[0].to_hash.should == {:msgid=>'xxx',:msgstr=>'yyy'}
    end

    it "parses a simple msgid and msg with additional whitespace" do
      t = PoFile.parse(%Q(  msgid    "xxx"   \n   msgstr    "yyy"   ))
      t[0].to_hash.should == {:msgid=>'xxx',:msgstr=>'yyy'}
    end

    it "parses an empty msgid with text (gettext meta data)" do
      t = PoFile.parse(%Q(msgid ""\nmsgstr "PLURAL FORMS"))
      t[0].to_hash.should == {:msgid=>'',:msgstr=>'PLURAL FORMS'}
    end

    it "parses a multiline msgid/msgstr" do
      t = PoFile.parse(%Q(msgid "xxx"\n"aaa"\n\n\nmsgstr ""\n"bbb"))
      t[0].to_hash.should == {:msgid=>'xxxaaa',:msgstr=>'bbb'}
    end

    it "parses simple comments" do
      t = PoFile.parse(%Q(#test\nmsgid "xxx"\nmsgstr "yyy"))
      t[0].to_hash.should == {:msgid=>'xxx',:msgstr=>'yyy',:comment=>"test\n"}
    end

    it "parses comments above msgstr" do
      t = PoFile.parse(%Q(#test\nmsgid "xxx"\n#another\nmsgstr "yyy"))
      t[0].to_hash.should == {:msgid=>'xxx',:msgstr=>'yyy',:comment=>"test\nanother\n"}
    end

    it "parses escaped quotes correctly" do
      t = PoFile.parse(%Q(msgid "xxx \\\"quoted\\\""\nmsgstr "yyy \\\"another quoted\\\""))
      t[0].to_hash.should == {msgid: 'xxx "quoted"', msgstr: 'yyy "another quoted"'}
    end

    it "parses escaped quotes correctly when using single quotes as delimiter" do
      t = PoFile.parse(%Q(msgid 'xxx \\\"quoted\\\"'\nmsgstr 'yyy \\\"another quoted\\\"'))
      t[0].to_hash.should == {msgid: 'xxx \"quoted\"', msgstr: 'yyy \"another quoted\"'}
    end
  end

  describe "instance interface" do
    it "adds two different translations" do
      p = PoFile.new
      p.add_translations_from_text(%Q(msgid "xxx"\nmsgstr "yyy"))
      p.add_translations_from_text(%Q(msgid "aaa"\nmsgstr "yyy"))
      p.translations[1].to_hash.should == {:msgid=>'aaa',:msgstr=>'yyy'}
    end

    it "can be initialized with translations" do
      p = PoFile.new(:translations=>['xxx'])
      p.translations[0].should == 'xxx'
    end

    it "can be converted to text" do
      text = %Q(msgid "xxx"\nmsgstr "aaa")
      p = PoFile.new
      p.add_translations_from_text(text)
      p.to_text.should == text
    end

    it "keeps uniqueness when converting to_text" do
      text = %Q(msgid "xxx"\nmsgstr "aaa")
      p = PoFile.new
      p.add_translations_from_text(%Q(msgid "xxx"\nmsgstr "yyy"))
      p.add_translations_from_text(text)
      p.to_text.should == text
    end
  end

  it "adds plural translations" do
    t = PoFile.parse(%Q(msgid "singular"\nmsgid_plural "plural"\nmsgstr[0] "one"\nmsgstr[1] "many"))
    t[0].to_hash.should == {:msgid=>['singular','plural'],:msgstr=>['one','many']}
  end

  it "does not fail on empty string" do
    PoFile.parse(%Q(\n\n\n\n\n))
  end

  it "shows line number for invalid strings" do
    begin
      PoFile.parse(%Q(\n\n\n\n\nmsgstr "))
      flunk
    rescue Exception => e
      e.to_s.should =~ /line 5/
    end
  end

  describe :to_text do
    it "is empty when not translations where added" do
      PoFile.to_text([]).should == ""
    end
    
    it "preserves simple syntax" do
      text = %Q(msgid "x"\nmsgstr "y")
      PoFile.to_text(PoFile.parse(text)).should == text
    end

    it "adds comments" do
      t = GetPomo::Translation.new
      t.msgid = 'a'
      t.msgstr = 'b'
      t.add_text("c\n",:to=>:comment)
      t.add_text("d\n",:to=>:comment)
      PoFile.to_text([t]).should == %Q(#c\n#d\nmsgid "a"\nmsgstr "b")
    end

    it "uses plural notation" do
      text = %Q(#awesome\nmsgid "one"\nmsgid_plural "many"\nmsgstr[0] "1"\nmsgstr[1] "n")
      PoFile.to_text(PoFile.parse(text)).should == text
    end

    it "only uses the latest of identicals msgids" do
      text = %Q(msgid "one"\nmsgstr "1"\nmsgid "one"\nmsgstr "001")
      PoFile.to_text(PoFile.parse(text)).should ==  %Q(msgid "one"\nmsgstr "001")
    end
  end

  describe :text_from_string do
    subject { PoFile.new.send(:text_from_string, string) }

    describe "string is wrapped in double quotes" do
      let(:string) { "\"foo \\\"bar\\\"\"" }

      it { should eql "foo \"bar\"" }
    end

    describe "string is wrapped in single quotes" do
      let(:string) { "'foo \\\"bar\\\"'" }

      it { should eql "foo \\\"bar\\\"" }
    end
  end
end
