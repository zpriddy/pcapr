# "THE BEER-WARE LICENSE" (Revision 42):
# Mu[http://www.mudynamics.com] wrote this file. As long as you retain this 
# notice you can do whatever you want with this stuff. If we meet some day, 
# and you think this stuff is worth it, you can buy us a beer in return. 
#
# All about pcapr
# * http://www.pcapr.net
# * http://groups.google.com/group/pcapr-forum
# * http://twitter.com/pcapr
#
# Mu Dynamics
# * http://www.mudynamics.com
# * http://labs.mudynamics.com

require 'rake'

Gem::Specification.new do |s|
    s.name         = 'xtractr'
    s.version      = "4.5.35634"
	s.author       = 'Mu Dynamics'
    s.description  = 'ruby API for programmatic interface to xtractr'
    s.summary      = 'ruby API for programmatic interface to xtractr'
    s.homepage     = 'http://www.pcapr.net/xtractr'
	s.date         = Time.now
    s.require_path = '.'
    s.files        = FileList['mu/xtractr.rb', 'mu/xtractr/*.rb'].to_a
    s.has_rdoc     = true
	s.rdoc_options = ['--inline-source', '--main', 'Mu::Xtractr']
	s.add_dependency('json', '>= 1.1.3')
end
