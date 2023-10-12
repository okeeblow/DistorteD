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

require('date')
require_relative('XROSS THE XOUL/lib/xross-the-xoul/version')
module COOLTRAINER
  module DistorteD

    # DD's epoch is the `btime` of the original `cooltrainer-image.rb` ♎
    BEGINNING_OF_LIFE = ::Time.new(2018, 9, 26, 9, 4, 11, in: ?R)

    # DD's version number is automatic.
    # - major version: years since epoch.
    # - minor version: days-of-year since epoch.
    VERSION = ::Time::now.yield_self {
      ::XROSS::THE::Version::TripleCounter.new(
         _1.year - BEGINNING_OF_LIFE.year,
        (_1.yday - BEGINNING_OF_LIFE.yday) % (::Date::gregorian_leap?(_1.year) ? 366 : 365),
        # Add a third level of differentiation here if I ever need to do two releases on the same day.
      )
    }

    I_WAS_THE_ONE = ::Hash[
      :required_ruby_version= => '>= 3.2.0',
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
