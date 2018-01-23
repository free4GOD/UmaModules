# vim: encoding=utf8

# Uma: La bot voladora de IRC de MontevideoLibre.
# Copyright (C) 2009  MontevideoLibre <http://www.montevideolibre.org/>
# Copyright (C) 2010  fcr <fcr@adinet.com.uy>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


set ::modules(tea,module,info) "The tea Module"
set ::modules(tea,module,author) "fcr (Francisco Castro) <fcr@adinet.com.uy>"
set ::modules(tea,module,author) "barbanegra (Mauricio Sosa Giri) <mauricio@seedwalk.net>"
set ::modules(tea,module,version) {$Rev$}
set ::modules(tea,module,namespace) ::modules::tea

# The command for the load event may be do_nothing or something
# like ::modules::youtube::on_load
::event::add -module tea -on load -command ::modules::tea::on_load
::event::add -module tea -on unload -command ::modules::tea::on_unload
::event::add -module tea -on msg.tea -command ::modules::tea::on_msg_tea
::event::add -module tea -on help.tea -command ::modules::tea::on_help_tea

namespace eval ::modules::tea {

  namespace import ::msgcat::mc

  array set tea_types {black 3m earlgrey 5m fruit 8m}

  proc on_load {} {
    # This code is run after loading the module
  }

  proc on_unload {} {
    variable tea_cups
    # This is called before unloading the module
    # If you want to cancel the unload process without repercutions then return
    # something different than "".
    foreach {nick data} [array get tea_cups] {
      after cancel [lindex $data 0]
    }
    return
  }

  proc send_help_tea {target } {
    sendto $target [mc "This is the tea module. Syntax: !tea TIME/TYPE"]
    sendto $target [mc "TIME may be: 2.5h, 42s, 17m or 17 for 17 minutes"]
    sendto $target [mc "see http://www.montevideolibre.org/chatirc:uma:modulo_tea"]
  }

  proc on_msg_tea {target header message} {
    variable tea_types
    variable tea_cups
    if {[lparse $message result] || [llength $result]!= 2} {
      send_help_tea $target
      return -code break
    }
    set type [string tolower [lindex $result 1]]
    set nick [string tolower [lindex [split [lindex $header 0] !] 0]]
    if {$type eq "cancel"} {
      if {[set time [cancel_tea_time $nick]] ne ""} {
	sendto $target [mc "Cancelation done. %s" $time]
      } else {
        sendto $target [mc "Tea not scheduled."]
      }
      return -code break
    }
    if {[info exists tea_types($type)]} {
      set type $tea_types($type)
    }
    if {![regexp {^(\d+\.?\d*|\d*\.\d+)(m|s|h|)$} $type -> time unit] ||
	![string is double $time]} {
      sendto $target [mc "Invalid type of tea."]
      return -code break
    }
    switch -- $unit {
      {s} {set ms [expr {1000 * $time}]}
      {} - {m} {set ms [expr {60000 * $time}]}
      {h} {set ms [expr {3600000 * $time}]}
    }
    if {$ms > 86400000} {
      sendto $target [mc "More than a day? wtf!"]
      return -code break
    }
    if {[info exists tea_cups($nick)]} {
      sendto $target [mc "You can't have more than one cup of tea."]
    } else {
      add_tea_time $target $nick $ms
      set left [expr {$ms / 60000 }]
      sendto $target [mc "Your tea will be ready in %d minutes." $left]
    }
  }

  proc cancel_tea_time {nick} {
    variable tea_cups
    if {![info exists tea_cups($nick)]} {
      return ""
    }
    foreach {id dsttime} $tea_cups($nick) {}
    unset tea_cups($nick)
    after cancel $id
    set curtime [clock seconds]
    if {$dsttime < $curtime} {
      return [mc "The message would be sent after a time machine being invented (just another weird and harmless race condition)."]
    }
    set left [expr {$dsttime - $curtime}]; # greater or equal than zero
    set textlist {}
    if {$left / 3600 > 1} {
      lappend textlist [mc "%d hours" [expr {$left / 3600}]]
    } elseif {$left / 3600 == 1} {
      lappend textlist [mc "%d hour" 1]
    }
    set left [expr {$left % 3600}]
    if {$left / 60 > 1} {
      lappend textlist [mc "%d minutes" [expr {$left / 60}]]
    } elseif {$left / 60 == 1} {
      lappend textlist [mc "%d minute" 1]
    }
    set left [expr {$left % 60}]
    if {$left > 1} {
      lappend textlist [mc "%d seconds" $left]
    } elseif {$left == 1} {
      lappend textlist [mc "%d second" 1]
    }
    switch [llength $textlist] {
      3 {return [mc "%s, %s and %s left" {*}$textlist]}
      2 {return [mc "%s and %s left" {*}$textlist]}
      1 {return [mc "%s left" {*}$textlist]}
      0 {return [mc "It would be sent now."]}
    }
  }

  proc add_tea_time {target nick ms} {
    variable tea_cups
    set id [after [expr {int($ms)}] [namespace code [list notify_ready $target $nick]]]
    set curtime [clock seconds]
    set dsttime [expr {int($ms/1000) + $curtime}]
    set tea_cups($nick) [list $id $dsttime]
  }

  proc notify_ready {target nick} {
    variable tea_cups
    sendto $target [mc "%s: ping!" $nick]
    sendto $target [mc "%s: Your tea is ready!!" $nick]
    unset tea_cups($nick)
  }
}
