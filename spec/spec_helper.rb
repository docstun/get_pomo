# ---- requirements
$LOAD_PATH.unshift File.expand_path("../lib", File.dirname(__FILE__))
require 'get_pomo'

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

# ---- Helpers
def pending_it(text,&block)
  it text do
    pending(&block)
  end
end
