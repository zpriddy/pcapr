# "THE BEER-WARE LICENSE" (Revision 42):
# Mu Dynamics wrote this file. As long as you retain this notice you can do 
# whatever you want with this stuff. If we meet some day, and you think this 
# stuff is worth it, you can buy us a beer in return. 
#
# http://www.pcapr.net
# http://groups.google.com/group/pcapr-forum
# http://labs.mudynamics.com
# http://twitter.com/pcapr

require 'test/unit'

Dir.glob('mu/xtractr/test/**/tc*.rb').each do |file|
    require file
end