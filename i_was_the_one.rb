#                                                                                                                       
#            `.........-`                                                                      `:/:::://.`              
#          `+/``+ssss:``-/:`                                                                 `:o+y. `::::-----``        
#         -+- :hmNNmdhs- `o++`             `-:--/                            -/...         ./shhyoy. +mmmmds+:--...`    
#       .//``odmNmmd+++` :+/h:-------------:+. ./...-..........---/--:.------//  -.--------//o//o+/+- :hhdmmmmmh/`-/-`  
#     `:+- :ymNmmyy:...-:` /: ./////////////-  ::/:/- `++++++++` -y  /:.`.////+-  /////- `/+++++++. :- .::+sydmNm+ `/+. 
#    -+:` /syyyo:--:+oso` /:  ---:::::::syys. -yoy+s` :mmmmmmmd- .h` ``:osshhyyy` /oshhs` -:::::::.  :: `-..-/dmo` `/yo:
#  `/o:--------:+syyy++``+s+++++++++/``:h+os``oshdos``odhhhddyy-`.h.`.ssyhmmdmoh/``o+mmho``:++++++++++y+``----::``-oyss.
#  +sssssssyyyyyhdmmsyo-+/----------.`.yooy-`-hodss/``---------.`.h-`.sohdhsymhsy.`:+yNmy/`.-----------:++ooooooo+sss+` 
#  `+dmmmdddddmmNNddhsyosooooooooooooooysoysssyymssssssssssssssssshyssyoh:` .mhsyssssodddyooooooooooooooysoyyyyyyyyy/   
#    /mNmdddhmdmmdy+-+mdhhhhhhhhhhhhhhhmhhyhhhmdmmdhhhhhhhhhhhhhhhdhhhsm+    ydddhhhhd-hdmdddddddddddddddyhdhdmmNms.    
#     .---.......`    -yhNmmhddhhhdhmhmhddmNNmyyy+dmNdydhyyyhddhmmmmNmhh.    -hyhNNNh: .mNmdmdddhhhdddmmyssssssso:      
#                       `/oooooooooooooo:`-+o+/.  `+oo+o++++ooo+oooooo-       `-+oo/`   :oooooooooooooo/                
#                                                                                                                       

require_relative('XROSS THE XOUL/lib/xross-the-xoul/version')
module COOLTRAINER
  module DistorteD

    VERSION = ::XROSS::THE::Version::TripleCounter.new(0, 7, 7)

    I_WAS_THE_ONE = ::Hash[
      :required_ruby_version= => '>= 3.1.0',
      :version=               => ::COOLTRAINER::DistorteD::VERSION,
      :authors=               => ['okeeblow'],
      :email=                 => ['root@cooltrainer.org'],
      :homepage=              => 'https://cooltrainer.org',
      :license=               => 'AGPL-3.0',
    ]

  end  # DistorteD
end  # COOLTRAINER

# Required reading:
# https://yehudakatz.com/2010/04/02/using-gemspecs-as-intended/
# https://yehudakatz.com/2010/12/16/clarifying-the-roles-of-the-gemspec-and-gemfile/
