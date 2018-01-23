# vim: encoding=utf8

# Uma: La bot voladora de IRC de MontevideoLibre.
# Copyright (C) 2009  MontevideoLibre <http://www.montevideolibre.org/>
# Copyright (C) 2010 barbanegra <mauricio@seedwalk.net>
# Copyright (C) 2011 barbanegra <mauricio@seedwalk.net>

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

package require http

set ::modules(weather,module,info) "The Weather Module"
set ::modules(weather,module,author) "barbanegra (Mauricio Sosa Giri) <mauricio@seedwalk.net>"
set ::modules(weather,module,version) {$Rev$}
set ::modules(weather,module,namespace) ::modules::weather

::event::add -module weather -on load -command ::modules::weather::on_load
::event::add -module weather -on unload -command ::modules::weather::on_unload
::event::add -module weather -on help.weather -command ::modules::weather::on_help_weather
::event::add -module weather -on msg.weather -command ::modules::weather::on_msg_weather
::event::add -module weather -on msg.metar -command ::modules::weather::on_msg_metar
::event::add -module weather -on msg.forecast -command ::modules::weather::on_msg_forecast
::event::add -module weather -on msg.taf -command ::modules::weather::on_msg_taf
::event::add -module weather -on msg.station -command ::modules::weather::on_msg_station


namespace eval ::modules::weather {
  namespace import ::msgcat::mc

  array set citycode {
    "MONTEVIDEO" SUMU "CANELONES" SUAA "ARTIGAS" SUAG
    "COLONIA" SUCA "DURAZNO" SUDU "MALDONADO" SUPE "MERCEDES" SUME
    "CERROLARGO" SUMO "PAYSANDU" SUPU "RIVERA" SURV "SALTO" SUSO
    "TACUAREMBO" SUTB "TREINTAYTRES" SUTR "ASUNCION" SGAS "BELEM" SBBE
    "CURITIBA" SBBI "BRASILIA" SBBR "FLORIANOPOLIS" SBFL "RIO" SBJR
    "MANAUS" SBMN "PORTOALEGRE" SBPA "ACAPULCO" MMAA "CANCUN" MMUN
    "TIJUANA" MMTJ "MEXICO" MMMX "MANAGUA" MNMG "BOGOTA" SKBO
    "MEDELLIN" SKMD "CARACAS" SVCS "QUITO" SEQU "LIMA" SPIM "LAPAZ" SLLP
    "ATACAMA" SCAT "GUALEGUAYCHU" SAAG "ROSARIO" SAAR "BUENOSAIRES" SABE
    "LAPLATA" SADL "MENDOZA" SAME "SANLUIS" SAOU "BAHIABLANCA" SAZB
    "PARIS" LFPG "LONDRES" EGLL "CORDOBA" SACO "MIAMI" KMIA "TOKYO" RJTT
    "TOKIO" RJTT "BARCELONA" LEBL "MADRID" LEMD "VALENCIA" LEVC
    "ANTARTIDA" SAWC "PANAMA" MPMG "SANSALVADOR" MSSS "SANTIAGO" SCEL
    "GROENLANDIA" BGTL "BARILOCHE" SAZS
  }
  array set sky_cond {
    "BKN" {Cloudy} "OVC" {Cover of clouds} "CLR" {Clear}
    "SKC" {Clear} "CAV" {Clear. Visibility: 10Km} "FEW" {Few clouds}
    "SCT" {Scattered clouds} "NSC" {No clouds below 1500m}
    "LTG" {Lightnings} "VCR" {Vecinity Rain} "VRB" {Variable}
  }
  array set phen_list {
    "RA" {Rain} "UP" {Precipitation not known}
    "GS" {Small hail and / or snow pellets} "GR" {Hail} "PE" {Snow pellets}
    "IC" {Ice crystals} "SG" {Snow grains} "SN" {Snow} "DZ" {Drizzle}
    "TS" {Thunderstorm} "FG" {Fog} "BR" {Fog} "FU" {Smoke}
    "VA" {Volcanic ashes} "DU" {Dust clouds} "SA" Sand "HZ" Mist
    "PO" {Swirls of sand / dust } "SQ" {Storm} "FC" {Tornado / Typhoon}
    "SS" {Sandstorm} "SS" {Duststorm}
    }
  array set rmk_list {"MIST" Niebla "BIRD" {Flocks of birds} "TORNADO" Tornado
    "FUNNEL CLOUD" {Funnel cloud} "WATERSPOUT" Typhoon
  }

  proc on_load {} {
    # This code is run after loading the module
  }

  proc on_unload {} {
    # This is called before unloading the module
    # If you want to cancel the unload process without repercutions then return
    # something different than "".
    return
  }
  proc on_help_weather {target header message} {
    sendto $target [mc "$target $message $header This module implements several commands to get all kind of meteorological stuff."]
    sendto $target [mc "The actual available commands are: !station !weather !forecast !metar !taf"]
    sendto $target [mc "To get more help about this commands use: !help !command"]
  }
  proc send_help_station {target header message} {
    sendto $target [mc "The weather module contains the !station command, and it's used"]
    sendto $target [mc "to obtain the station identifier code, from the city name provided."]
    sendto $target [mc "Example: !station Tijuana"] 
  }
  proc send_help_metar {target header message} {
    sendto $target [mc "The weather module contains the !metar command, and it's used"]
    sendto $target [mc "to obtain meteorological data, from the station code provided."]
    sendto $target [mc "Example: !metar SUMU"]
  }
  proc send_help_weather {target header message} {
    sendto $target [mc "The weather module contains the !weather command, and it's used"]
    sendto $target [mc "to obtain meteorological data, from the city name provided."]
    sendto $target [mc "Example: !weather Groenlandia - Default (if none provided): Montevideo"]
  }
  proc send_help_taf {target header message} {
    sendto $target [mc "The weather module contains the !taf command, and it's used"]
    sendto $target [mc "to obtain forecast meteorological data, from the station code provided."]
    sendto $target [mc "Example: !taf SABE"]
  }
  proc send_help_forecast {target header message} {
    sendto $target [mc "This module implements the !weather command, and it's used"]
    sendto $target [mc "to obtain forecast meteorological data, from the city name provided."]
    sendto $target [mc "Example: !forecast Atacama - Default (if none provided): Montevideo"]
  }
  proc get_metar_code {target header message city command} {
    variable citycode
    if {$city eq ""} {
      switch $command {
       	{weather} { set city "Montevideo" }
      	{forecast} { set city "Montevideo" }
        {station} { send_help_station $target $header $message; return }
      }
    }
    set tag [string map {" " "" "\"" "" Á A É E Í I Ó O Ú U Ñ N} [string toupper $city]]
    if {![info exists citycode($tag)]} {
      sendto $target [mc "%s city wasn't found in the database." $city]
      return
    }
    return $citycode($tag)
  }
  
  proc get_data {station type} {
    if { $type eq "metar"} {
      set url "http://140.90.128.70/pub/data/observations/metar/stations/$station.TXT"
    } else {
      set url "http://140.90.128.70/pub/data/forecasts/taf/stations/$station.TXT"
    }
    if {[catch {http::geturl $url} tmp]} {
      puts [mc "|weather module| - Error: Couldn't obtain data: URL: %s"] $error_msg $url
      return "error"
    }
    if {[http::ncode $tmp] == 200} {
      set rawtxt [http::data $tmp]
      lparse $rawtxt txt
      puts [mc "|weather module| - data obtained:\n%s" $txt]
      return $txt
    } else {
      puts [mc "|weather module| - Command: %1\$s Error %2\$s" $type [http::ncode $tmp]]
      return "error"
    }
    http::cleanup $tmp
  }

  proc on_msg_station {target header message} {
    set city [lrange $message 1 end]
    set code [get_metar_code $target $header $message $city "station"]
    if {$code eq ""} {
      return -code break
    }
    sendto $target [mc "The METAR code for %1\$s is: %2\$s." $city $code]
    return -code break
  }

  proc on_msg_metar {target header message} {
    set station [lindex $message 1]
    if {$station eq ""} {
      send_help_metar $target $header $message
      return -code break
    }
    set metardata [get_data [string toupper $station] "metar"]
    if {$metardata eq "error"} {
      sendto $target [mc "Error: Station or Data not found."]
    } else {
      set inform [parse_metar_code $metardata $station]
      sendto $target $inform
    }
    return -code break
  }
  
  proc on_msg_weather {target header message} {
    set city [lrange $message 1 end]
    set code [get_metar_code $target $header $message $city "weather"]
    if {$code eq ""} {
      return -code break
    }
    set metardata [get_data $code "metar"]
    if {$metardata eq "error"} {
      sendto $target [mc "Error: Station or Data not found."]
    } else {
      set inform [parse_weather_code $metardata $code]
      sendto $target $inform
    }
    return -code break
  }
  
  proc on_msg_taf {target header message} {
    set station [lindex $message 1]
    if {$station eq ""} {
      send_help_taf $target $header $message
      return -code break
    }
    set metardata [get_data [string toupper $station] "taf"]
    if {$metardata eq "error"} {
      sendto $target [mc "Error: Station or Data not found."]
    } else {
      set inform [parse_taf_code $metardata $station]
      sendto $target $inform
    }
    return -code break
  }
  
  proc on_msg_forecast {target header message} {
    set city [lrange $message 1 end]
    set code [get_metar_code $target $header $message $city "forecast"]
    if {$code eq ""} {
      return -code break
    }
    set metardata [get_data $code "taf"]
    if {$metardata eq "error"} {
      sendto $target [mc "Error: Station or Data not found."]
    } else {
      set inform [parse_forecast_code $metardata $code]
      sendto $target $inform
    }
    return -code break
  }
  
  proc parse_metar_code {metardata station} {
    set hour [lindex $metardata 1]
    set date [split [lindex $metardata 0] "/"]
    set lastupdt [mc "Current Weather Full Report - Station: %1\$s\nLast update: %2\$s/%3\$s/%4\$s %5\$s UTC" $station [lindex $date 2] [lindex $date 1] [lindex $date 0] $hour]
    set values [lrange $metardata 3 end]
    set report "$lastupdt\n"
    foreach token $values {
      switch -regexp -- $token {
        {^\d{5}(G\d{2,3})?(KT|MPS)$} { #wind
          regexp {(\d{3})(\d+)G?(\d*)([A-Z]+)} $token -> wind_dir wind_speed wind_gust units
          if {$units eq "KT"} {
	    set mult 1.854
	  } elseif {$units eq "MPS"} {
	    set mult 3.6
          } elseif {$units eq "MPH"} {
	    set mult 1.609
          } elseif {$units eq "KMH"} {
	    set mult 1.0
	  } else {
	    error [mc "unkown wind meassure unit"]
	  }
	  if {[scan $wind_dir %d wind_dir] > 0} {
	    set magic [expr {int(($wind_dir)/45)}]
	    set rprt_wind_dir [lindex {N NE E SE S SW W NW N} $magic]
	  } else {
	    set rprt_wind_dir [mc " Variable"]
	  }
	  if {[scan $wind_speed %d wind_speed] != 1} {
	    continue
	  }
	  set rprt_wind_speed [expr {round($mult*$wind_speed)}]
	  append rprt_wind [mc "Wind: Speed: %1\$sKm/h Direction: %2\$s " $rprt_wind_speed $rprt_wind_dir]
	  if {[scan $wind_gust %d wind_gust] > 0} {
	    set rprt_wind_gust [expr {round($mult*$wind_gust)}]
	    append rprt_wind [mc "Gusts: %sKm/h " $rprt_wind_gust]
	  }
	  append report $rprt_wind
	} {M?\d+/M?\d+} { #temperature and dewpoint
	  if {[string length $token] == 5} {
	    set temptoken [string map {M -} $token]
	    set rprt_temp_val [lindex [split $temptoken "/"] 0]
	    set rprt_temp_dwp [lindex [split $temptoken "/"] 1]
	    set rprt_temp [mc "Temperature: %1\$s°C Dewpoint: %2\$s°C. " $rprt_temp_val $rprt_temp_dwp]
	    append report $rprt_temp
	  }
	} {[AQ]\d{4}} { #pressure
	  set rprt_pres_type [string index $token 0]
	  set rprt_pres_val [string trim $token {"[AQ]*"}]
	  switch -- $rprt_pres_type {
	    {Q} {
	      append report [mc "Pressure: %shPa " $rprt_pres_val]
	    } {A} {
	      #TODO add units to this value
	      append report [mc "Pressure: %s " $rprt_pres_val]
	    } default {
	      append report [mc "Pressure: No available. "]
	    }
	  }
	} {^(\d{4})$} { #visibility
	  set visib [expr {round($token/1000.0)}]
	  append report [mc "Visibility: %sKm " $visib]
	} {^[A-Z]{3}(\d{3})?([A-Z]{3})?|CAVOK|VCRA$} { #sky
          variable sky_cond
          if {[info exists sky_cond([string range $token 0 2])]} {
            set cond $sky_cond([string range $token 0 2])
            set rprt_sky_cond [lrange $cond 0 end]
            set rprt_sky_clouds [string range $token 3 5]
            append report [mc "Sky: %s " $rprt_sky_cond]
            if {[string is integer -strict $rprt_sky_clouds] } {
              set rprt_sky_clouds_height [expr {round($rprt_sky_clouds*100.0*0.3048)}]
              append report [mc "%1\$s at %2\$sm " $rprt_sky_cond $rprt_sky_clouds_height]
            }
          }
        } {^[+-]?([A-Z]{2})+$} { #phen
          variable phen_list
          if {[string is upper [string index $token 0]]} {
            set phen_code [string range $token 0 1]
          } else {
            set phen_code [string range $token 1 2]
          } 
          if {[info exists phen_list($phen_code)]} {
            set phen $phen_list($phen_code)
            append report [mc "Condition: %s " $phen]
            if {[string index $token 0] eq "+"} {
              append report [mc "Heavy "]
            } elseif {[string index $token 0] eq "-"} {
              append report [mc "Light "]
	    }
          }
	} {^[A-Z]+$} { #remarks
          variable rmk_list
          set remark $rmk_list([string range $token 0 end])
          if {[llength $remark] != 0} {
            set rmk_type [lrange $remark 0 end]
            append report [mc "Remark: %s " $rmk_type]
          }
        }
      }
    }
    puts [mc "|weather module| - METAR data parsed."]
    return $report
  }

  proc parse_weather_code {metardata station} {
    set dates [split [lindex $metardata 0] "/"]
    set frmt_date "[lindex $dates 2]/[lindex $dates 1]/[lindex $dates 0]"
    set hours [string range [lindex $metardata 1] 0 1]
    #FIXME crazy hours from 00 to 03AM
    set frmt_hour [mc "[expr [scan $hours %d] - 3]:00 UYT"]
    set values [lrange $metardata 3 end]
    foreach token $values {
      switch -regexp -- $token {
	{^(METAR|SPECI)$} { # station
	  set rprt_type $token
	} {^(\d{6})Z$} { # date and time
	  set rprt_time $token
	} {^\d{5}(G\d{2,3})?(KT|MPS)$} { #wind
          regexp {(\d{3})(\d+)G?(\d*)([A-Z]+)} $token -> wind_dir wind_speed wind_gust units
          if {$units eq "KT"} {
	    set mult 1.854
	  } elseif {$units eq "MPS"} {
	    set mult 3.6
          } elseif {$units eq "MPH"} {
	    set mult 1.609
          } elseif {$units eq "KMH"} {
	    set mult 1.0
	  } else {
	    error "unkown wind meassure unit"
	  }
	  if {[scan $wind_dir %d wind_dir] > 0} {
	    set magic [expr {int(($wind_dir)/45)}]
	    set rprt_wind_dir [lindex {N NE E SE S SW W NW N} $magic]
	  } else {
	    set rprt_wind_dir " Variable"
	  }
	  if {[scan $wind_speed %d wind_speed] != 1} {
	    continue
	  }
	  set rprt_wind_speed [expr {round($mult*$wind_speed)}]
	  append rprt_wind [mc "%1\$sKm/h from %2\$s" $rprt_wind_speed $rprt_wind_dir]
	  if {[scan $wind_gust %d wind_gust] > 0} {
            set rprt_wind_gust [expr {round($mult*$wind_gust)}]
	    append rprt_wind [mc "Gusts: %sKm/h" $rprt_wind_gust]
	  }
	}
	{M?\d+/M?\d+} { #temperature
	  if {[string length $token] == 5} {
	    set temptoken [string map {M -} $token]
            set rprt_temp_val [lindex [split $temptoken "/"] 0]
	    set rprt_temp [mc "%s°C" $rprt_temp_val]
	  }
	}
	{[AQ]\d{4}} { #pressure
	  set rprt_pres_type [string index $token 0]
	  set rprt_pres_val [string trim $token {"[AQ]*"}]
	  switch -- $rprt_pres_type {
	    {Q} {
	      set rprt_press [mc "%shPa" $rprt_pres_val]
	    }
	    {A} { #TODO add units to this value
	      set rprt_press "$rprt_pres_val"
	    }
	    default {
	      set rprt_press [mc "Not available."]
	    }
	  }
	}
	{^(\d{4})$} { #visibility
	  set visib [expr {round($token/1000.0)}]
          set rprt_visib [mc "%sKm" $visib]
	}
	{^[A-Z]{3}(\d{3})?([A-Z]{3})?|CAVOK$} { #sky
          variable sky_cond
          if {[info exists sky_cond([string range $token 0 2])]} {
            set rprt_sky $sky_cond([string range $token 0 2])
          }
        }
	{^[+-]?([A-Z]{2})+$} { #phen
          variable phen_list
          if {[string is upper [string index $token 0]]} {
            if {[info exists phen_list([string range $token 0 1])]} {
              set rprt_phen $phen_list([string range $token 0 1])
            }
          } else {
            if {[info exists phen_list([string range $token 1 2])]} {
              set phen $phen_list([string range $token 1 2])
            }
	    if {[string index $token 0] eq "+"} {
	      set rprt_phen [mc "Heavy %s" $phen]
	    } elseif {[string index $token 0] eq "-"} {
	      set rprt_phen [mc "Light %s" $phen]
	    }
	  }
	}
        {^[A-Z]+$} { #remarks
          variable rmk_list
          if {[info exists rmk_list([string range $token 0 end])]} {
            set rprt_rmrk $rmk_list([string range $token 0 end])
          }
        }
      }
    }
    set report [mc "Weather Report - Station: %1\$s Update: %2\$s %3\$s \n" $station $frmt_date $frmt_hour]
    if {[info exists rprt_temp]} {
      append report [mc "Temperature: %s " $rprt_temp]
    }
    if {[info exists rprt_sky]} {
      append report [mc "Sky: %s. " $rprt_sky]
    }
    append report "\n"
    if {[info exists rprt_wind]} {
      append report [mc "Wind: %s. " $rprt_wind]
    }
    if {[info exists rprt_press]} {
      append report [mc "Pressure: %s. " $rprt_press]
    }
    if {[info exists rprt_visib]} {
      append report [mc "Visibility: %s. " $rprt_visib]
    }
    if {[info exists rprt_rmrk]} {
      append report "\n"
      append report [mc "Danger: %s. " $rprt_rmrk]
    }
    if {[info exists rprt_phen]} {
      append report "\n"
      append report [mc "Condition: %s. " $rprt_phen]
    }
    puts [mc "|weather module| - METAR data parsed."]
    return $report
  }
  
  proc parse_taf_code {tafdata station} {
    set values [lrange $tafdata 3 end]
    set report "Weather Forecast Complete - Station: $station\n"
    foreach token $values {
      switch -regexp -- $token {
        {^\d{6}Z$} { ; #date and time the report was issued
          set date [string range $token 0 1]
          set hour [string range $token 2 3]
          append report [mc "Report issued on the %1\$sth day of the month at %2\$s:00 UTC\n" $date $hour]
        } {^\d{4}/\d{4}$} {
          set date_start [string range $token 0 1]
          set hour_start [string range $token 2 3]
          set date_end [string range $token 5 6]
          set hour_end [string range $token 7 8]
          append report [mc "valid from the %1\$sth at %2\$s:00 UTC until the %3\$sth at %4\$s:00 UTC\n" $date_start $hour_start $date_end $hour_end]
        } {^TEMPO$} {
          append report "\nTemporary Condition "
        } {^BECMG$} {
          append report "\nBecoming Condition "
        } {^FM(\d{0,6})?$} {
          append report "\nRapid Weather Change "
        } {^PROB\d{2}$} {
          set probability [string range $token 4 5]
          append report [mc "\nFollowing Condition probability: %s " $probability]
        } {^\d{5}(G\d{2,3})?(KT|MPS)$} { ; #wind
	  regexp {(\d{3})(\d+)G?(\d*)([A-Z]+)} $token -> wind_dir wind_speed wind_gust units
          if {$units eq "KT"} {
	    set mult 1.854
	  } elseif {$units eq "MPS"} {
	    set mult 3.6
          } elseif {$units eq "MPH"} {
	    set mult 1.609
          } elseif {$units eq "KMH"} {
	    set mult 1.0
            	  } else {
	    error "Unrecognized wind speed unit"
	  }
	  if {[scan $wind_speed %d wind_dir] > 0} {
	    set magic [expr {int(($wind_dir)/45)}]
	    set rprt_wind_dir [lindex {N NE E SE S SW W NW N} $magic]
	  } else {
	    set rprt_wind_dir " Variable"
	  }
	  if {[scan $wind_speed %d wind_speed] != 1} {
	    continue
	  }
	  set rprt_wind_speed [expr {round($mult*$wind_speed)}]
	  append rprt_wind [mc "Wind: Speed: %1\$sKm/h Direction: %2\$s " $rprt_wind_speed $rprt_wind_dir]
	  if {[scan $wind_gust %d wind_gust] > 0} {
	    set rprt_wind_gust [expr {round($mult*$wind_gust)}]
	    append rprt_wind [mc "Gusts: %sKm/h " $rprt_wind_gust]
	  }
	  append report $rprt_wind
	} {^TX(\d{2})/(\d{2,4})Z?$} { ; #Max Temperature
	  if {[string length $token] == 10} {
	    set temptoken [string map {M -} $token]
	    set rprt_temp_val [string range $token 2 3]
            set rprt_temp_start [string range $token 5 6]
            set rprt_temp_end [string range $token 7 8]
            set rprt_temp [mc "\nMaximum Temperature: %1\$s°C between %2\$s:00 and %3\$s:00 UTC." $rprt_temp_val $rprt_temp_start $rprt_temp_end]
            append report $rprt_temp
	  }
	} {^TN(\d{2})/(\d{2,4})Z?$} { ; #Min Temperature
	  if {[string length $token] == 10} {
	    set temptoken [string map {M -} $token]
	    set rprt_temp_val [string range $token 2 3]
            set rprt_temp_start [string range $token 5 6]
            set rprt_temp_end [string range $token 7 8]
            set rprt_temp [mc "\nMinimum Temperature: %1\$s°C between %2\$s:00 and %3\$s:00 UTC." $rprt_temp_val $rprt_temp_start $rprt_temp_end]
            append report $rprt_temp
	  }
        } {[AQ]\d{4}} { #pressure
	  set rprt_pres_type [string index $token 0]
	  set rprt_pres_val [string trim $token {"[AQ]*"}]
	  switch -- $rprt_pres_type {
	    {Q} {
	      append report [mc " Pressure: %shPa " $rprt_pres_val]
	    }
	    {A} {
	      #TODO add units to this value
	      append report " Pressure: $rprt_pres_val "
	    }
	    default {
	      append report "Pressure: No available. "
	    }
	  }
	} {^(\d{4})|P(\d{1,2})SM$} { ; #visibility
          if {[string index $token 0] eq "P"} {
            if {[string length $token == 5]} {
              set visib [expr {round([string range $token 1 2]*1.609)}] 
            } else {
              set visib [expr {round([string index $token 1]*1.609)}]
            }
          } elseif {[string range $token end-1 end] eq "SM"} {
            set visib [expr {round([string range $token 0 end-2]*1.609)}] 
          } else {
	    set visib [expr {round([scan $token %d]/1000.0)}]
          }
          append report [mc " Visibility: %sKm " $visib]
        } {^[A-Z]{3}(\d{3})?([A-Z]{3})?|CAVOK$} { ; #sky
          variable sky_cond
          set cond [array get sky_cond [string range $token 0 2]]
	  if {[llength $cond]!=0} {
	    set rprt_sky_cond [lindex $cond 1]
	    if {$token eq "CAVOK"} {
	      append report $rprt_sky_cond
	    } else {
              set rprt_sky_clouds [string range $token 3 5]
	      if {[string is integer -strict $rprt_sky_clouds] } {
		set rprt_sky_clouds_height [expr {round($rprt_sky_clouds*100.0*0.3048)}]
		append report [mc " %1\$s at %2\$sm " $rprt_sky_cond $rprt_sky_clouds_height]
              }
            }
          }
        } {^[+-]?([A-Z]{2})$} { ; #phen
          variable phen_list
	  if {[string is upper [string index $token 0]]} {
	    set phen [array get phen_list [string range $token 0 1]]
	  } else {
	    set phen [array get phen_list [string range $token 1 2]]
	  }
	  if {[llength $phen] != 0} {
            set phen_type [lindex $phen 1]
            append report " Condition: "
            if {[string index $token 0] eq "+"} {
              append report "Heavy "
	    } elseif {[string index $token 0] eq "-"} {
	      append report "Light "
	    }
	    append report "$phen_type"
	  }
	} {^[A-Z]+$} { ; #remarks
          variable rmk_list
	  set remark [array get rmk_list [string range $token 0 end]]
	  if {[llength $remark] != 0} {
	    set rmk_type [lrange $remark 0 end]
	    append report "Remark: $rmk_type "
	  }
        }
      }
    }
    puts [mc "|weather module| - TAF data parsed."]
    return $report
  }
  
  proc parse_forecast_code {tafdata station} {
    set values [lrange $tafdata 3 end]
    foreach token $values {
      switch -regexp -- $token {
        {^\d{6}Z$} { ; #date and time the report was issued
          set date [string range $token 0 1]
          set hour [string range $token 2 3]
	}
        {^\d{4}/\d{4}$} { # valid time period
          if {![info exists tmpdate_start]} {
            set tmpdate_start [string range $token 0 1]
            set tmphour_start [string range $token 2 3]
            set tmpdate_end [string range $token 5 6]
            set tmphour_end [string range $token 7 8]
          }
        }
        {^\d{5}(G\d{2,3})?(KT|MPS)$} { #wind
          if {[info exists rprt_wind]} {
            return -code break
          }
          regexp {(\d{3})(\d+)G?(\d*)([A-Z]+)} $token -> wind_dir wind_speed wind_gust units
          if {$units eq "KT"} {
            set mult 1.854
          } elseif {$units eq "MPS"} {
            set mult 3.6
          } elseif {$units eq "MPH"} {
            set mult 1.609
          } elseif {$units eq "KMH"} {
            set mult 1.0
          } else {
            error "|weather module| - Unrecognized wind speed unit"
          }
          if {[scan $wind_speed %d wind_dir] > 0} {
            set magic [expr {int(($wind_dir)/45)}]
            set rprt_wind_dir [lindex {N NE E SE S SW W NW N} $magic]
          } else {
            set rprt_wind_dir " Variable"
          }
          if {[scan $wind_speed %d wind_speed] != 1} {
            continue
          }
          set rprt_wind_speed [expr {round($mult*$wind_speed)}]
          if {[scan $wind_gust %d wind_gust] > 0} {
            set rprt_wind_gust [expr {round($mult*$wind_gust)}]
          }
        }
        {^TX(M)?(\d{2})/(\d{2,4})Z?$} { #Max Temperature
            set temptoken [string map {T "" X "" M -} $token]
            set rprt_temp_max [lindex [split $temptoken "/"] 0]
        }
        {^TN(M)?(\d{2})/(\d{2,4})Z?$} { #Min Temperature
            set temptoken [string map {T "" N "" M -} $token]
            set rprt_temp_min [lindex [split $temptoken "/"] 0]
        }
        {^(\d{4})|P(\d{1,2})SM$} { #visibility
          if {[info exists rprt_visib]} {
            continue
          }
          if {[string index $token 0] eq "P"} {
            if {[string length $token] == 5} {
              set rprt_visib [expr {round([string range $token 1 2]*1.609)}] 
            } else {
              set rprt_visib [expr {round([string index $token 1]*1.609)}]
            }
          } elseif {[string range $token end-1 end] eq "SM"} {
            set rprt_visib [expr {round([string range $token 0 end-2]*1.609)}] 
          } else {
            set rprt_visib [expr {round([scan $token %d]/1000.0)}]
          }
        }
        {^[A-Z]{3}(\d{3})?([A-Z]{3})?|(CAVOK)$} { #sky
          if {[info exists rprt_sky]} {
            continue
          }
          variable sky_cond
          if {![info exists rprt_sky]} {
            if {[info exists sky_cond([string range $token 0 2])]} {
              if { $token eq "CAVOK" } {
                set rprt_visib "10"
                set rprt_sky "Clear"
              } else {
                set rprt_sky $sky_cond([string range $token 0 2])
              }
            }
          }
        }
        {^[+-]?([A-Z]{2})$} { #phen
          variable phen_list
          if {[string is upper [string index $token 0]]} {
            set phen [array get phen_list [string range $token 0 1]]
          } else {
            set phen [array get phen_list [string range $token 1 2]]
          }
          if {[llength $phen] != 0} {
            set rprt_phen [lindex $phen 1]
            if {[string index $token 0] eq "+"} {
              append rprt_phen " Heavy"
            } elseif {[string index $token 0] eq "-"} {
              append rprt_phen " Light"
            }
          }
        }
        {^[A-Z]+$} { #remarks
          variable rmk_list
          set remark [array get rmk_list [string range $token 0 end]]
          if {[llength $remark] != 0} {
            append rprt_rmk [lrange $remark 0 end]
          }
        }
      }
    }
    set report "Weather Forecast Optimized - Station: $station\n"
    if {[info exists date]} {
      #FIXME crazy hours from 00 to 03AM
      set month [clock format [clock seconds] -format %B]
      append report [mc "Issued: %1\$sth %2\$s. At %3\$s:00 UYT. " $date $month [expr [scan $hour %d] - 3]]
    }
    if {[info exists tmpdate_start]} {
    #FIXME crazy hours from 00 to 03AM
      append report [mc "Valid between %1\$sth %2\$s:00 and %3\$sth %4\$s:00 UYT" $tmpdate_start [expr [scan $tmphour_start %d] - 3] $tmpdate_end [expr [scan $tmphour_end %d] - 3]]
    }
    append report "\n"
    if {[info exists rprt_temp_max] && [info exists rprt_temp_min]} {
      append report [mc "Temperature: Min: %1\$s°C Max: %2\$s°C" $rprt_temp_min $rprt_temp_max]
    }
    append report " "
    if {[info exists rprt_sky]} {
      append report [mc "Sky: %s" $rprt_sky]
    }
    append report "\n"
    if {[info exists rprt_wind_dir]} {
      append report  [mc "Wind: Speed: %1\$sKm/h Direction: %2\$s" $rprt_wind_speed $rprt_wind_dir]
    }
    if {[info exists rprt_wind_gust]} {
      append report  [mc " Gusts: %sKm/h." $rprt_wind_gust]
    }
    append report " "
    if {[info exists rprt_press]} {
      append report [mc "Pressure: %s." $rprt_press]
    }
    append report " "
    if {[info exists rprt_visib]} {
      append report [mc "Visibility: %sKm." $rprt_visib]
    }
    append report "\n"
    if {[info exists rprt_phen]} {
      append report [mc "Condition: %s. " $rprt_phen]
    }
    if {[info exists rprt_rmk]} {
      append report [mc "Danger: %s." $rprt_rmk]
    }
    append report "\n"
    puts [mc "|weather module| - TAF data parsed."]
    return $report
  }
}