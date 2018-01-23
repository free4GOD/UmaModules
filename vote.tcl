# vim: encoding=utf8

# Uma: La bot voladora de IRC de MontevideoLibre.
# Copyright (C) 2009  MontevideoLibre <http://www.montevideolibre.org/>
# Copyright (C) 2010  barbanegra <mauricio@seedwalk.net>
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


set ::modules(vote,module,info) "The direct democracy Module"
set ::modules(vote,module,author) "barbanegra (Mauricio Sosa Giri) <mauricio@seedwalk.net>"
set ::modules(vote,module,version) {$Rev$}
set ::modules(vote,module,namespace) ::modules::vote

# The command for the load event may be do_nothing or something
# like ::modules::youtube::on_load
::event::add -module vote -on load -command ::modules::vote::on_load
::event::add -module vote -on unload -command ::modules::vote::on_unload
::event::add -module vote -on msg.vote -command ::modules::vote::on_msg_vote
::event::add -module vote -on help.vote -command ::modules::vote::on_help_vote

namespace eval ::modules::vote {

  namespace import ::msgcat::mc

  proc on_load {} {
  }

  proc on_unload {} {
    variable votation
    if {[info exists votation]} {
      after cancel [lindex $votation 0]
    }
    return
  }

  proc send_help_vote {target } {
    sendto $target [mc "This is the direct democracy module."]
    sendto $target [mc "Start poll: !vote start \"¿Will it rain tomorrow? \". The votation will be active for 72 hours."]
    sendto $target [mc "Voting: !vote yes/no. More information in http://www.montevideolibre.org/chatirc:uma:modulo_vote"]
  }

  proc on_msg_vote {target header message} {
    variable votation
    variable voters
    if {[lparse $message params] || [llength $params] < 2} {
      send_help_vote $target
      return -code break
    }
    set nick [string tolower [lindex [split [lindex $header 0] !] 0]]
    set option [string tolower [lindex $params 1]]
    set usr [string tolower [lindex [split [lindex $header 0] !] 0]]
    switch -- $option {
      {yes} {
	::event::run auth is_identified -command [list ::modules::vote::add $target $usr yes] $usr
      }
      {no} {
	::event::run auth is_identified -command [list ::modules::vote::add $target $usr no] $usr
      }
      {status} {
	sendto $target [status "partial"]
      }
      {stop} {
	if {![info exists ::conf::vote_admins]} {
	  sendto $target [mc "::conf::vote_admins not configured."]
	  return -code break
	}
	if {[lsearch $::conf::vote_admins $usr] < 0} {
	  sendto $target [mc "You don't have permission to create polls, request to be added to ::conf::vote_admins"]
	  return -code break
	}
	::event::run auth is_identified -command [list ::modules::vote::stop $target] $usr
      }			
      {cancel} {
	if {![info exists ::conf::vote_admins]} {
	  sendto $target [mc "::conf::vote_admins not configured."]
	} elseif {[lsearch $::conf::vote_admins $usr] < 0} {
	  sendto $target [mc "You don't have permission to create polls, request to be added to ::conf::vote_admins"]
	} else {
	  ::event::run auth is_identified -command [list ::modules::vote::cancel $target] $usr
	}
      }
      {start} {
	if {[llength $params] < 3} {
	  sendto $target [mc "Syntax error"]
	} elseif {![info exists ::conf::vote_admins]} {
	  sendto $target [mc "::conf::vote_admins not configured."]
	} elseif {[lsearch $::conf::vote_admins $usr] < 0} {
	  sendto $target [mc "You don't have permission to create polls, request to be added to ::conf::vote_admins"]
	} else {
	  set subj [lrange $params 2 end]
	  ::event::run auth is_identified -command [list ::modules::vote::start $target $usr $subj] $usr
	}
      }
      {default} {
	send_help_vote $target
      }
    }
    return -code break
  }

  proc start {target applicant subject is_identified} {
    if {!$is_identified} {
      sendto $target [mc "You must be identified to create a poll."]
      return
    }
    # some checks are done after the identification check process, and
    # this is because the votation could be cancelled in the middle.
    variable votation
    variable voters
    if {[info exists votation]} {
      sendto $target [mc "There's already a votation in course."];
      return
    }
    set id [after 259200000 [namespace code [list stop $target 1]]]
    set startime [clock seconds]
    set endtime [expr { 259200 + $startime}]
    set votation [list $id $subject $applicant $endtime]
    array set voters {}
    sendto $target [mc "Poll started. Default end: 72 hours."]
  }

  proc add {target nick vote is_identified} {
    if {!$is_identified} {
      sendto $target [mc "You must be identified to vote."]
      return
    }
    variable votation
    variable voters
    if {![info exists votation]} {
      sendto $target [mc "There's no running votation"]
      return
    }
    if {[info exists voters($nick)]} {
      sendto $target [mc "You won't be able to vote again."]
      return
    }
    set voters($nick) [expr {!!$vote}]; # 0 if "no", 1 if "yes".
    sendto $target [mc "%s: Your vote was accepted." $nick]
  }

  proc status {type} {
    variable votation
    variable voters
    set positive 0
    if {![info exists votation]} {
      return [mc "No polls running at the moment."];
    }
    set subject [lindex $votation 1]
    set applicant [lindex $votation 2]
    set total [array size voters]
    set pro_votes {}
    set counter_votes {}
    foreach {person choice} [array get voters] {
      incr positive $choice
      if {$choice} {
	lappend pro_votes $person
      } else {
	lappend counter_votes $person
      }
    }
    set negative [expr {$total - $positive}]
    set endtime [lindex $votation 3]
    set timeleft [expr {($endtime - [clock seconds])/3600}];
    set msg ""
    switch -- $type {
      {partial} {
	append msg [mc "Partial results - Votation: %s Given by: %s\n" $subject $applicant]
	append msg [mc "In favor: %d Against: %d Total: %d Time left: %d hours" $positive $negative $total $timeleft]
      }
      {final} {
	append msg [mc "Final results - Votation: %s Given by: %s.\n" $subject $applicant]
	append msg [mc "In favor: %d Against: %d Total: %d Time left: %d hours.\n" $positive $negative $total $timeleft]
	append msg [mc "Participants - In favor: %s Against: %s." [join $pro_votes] [join $counter_votes]]
      }
    }
    return $msg
  }

  proc stop {target is_identified} {
    if {!$is_identified} {
      sendto $target [mc "You must be identified to stop votations."]
      return
    }
    variable votation
    variable voters
    if {![info exists votation]} {
      sendto $target [mc "There's no running votation"]
      return
    }
    after cancel [lindex $votation 0]
    sendto $target [status "final"]
    unset votation
    unset voters
  }

  proc cancel {target is_identified} {
    if {!$is_identified} {
      sendto $target [mc "You must be identified to cancel the poll."]
      return
    }
    variable votation
    variable voters
    if {![info exists votation]} {
      sendto $target [mc "There's no running votation"]
      return
    }
    after cancel [lindex $votation 0]
    unset votation
    unset voters
    sendto $target [mc "The poll has been cancelled."]	
  }
}
