 proc parse_metar_code {metardata station} {
    set hour [lindex $metardata 1]
    set date [split [lindex $metardata 0] "/"]
    set lastupdt [mc "Current Weather Full Report - Station: %1\$s\nLast update: %2\$s/%3\$s/%4\$s %5\$s UTC" $station [lindex $date 2] [lindex $date 1] [lindex $date 0] $hour]
    set values [lrange $metardata 3 end]
    set report "$lastupdt\n"
    foreach token $values {
      switch -regexp -- $token {
        {^\d(G\d)?(KT|MPS)$} { #wind
          regexp {(\d)(\d+)G?(\d*)([A-Z]+)} $token -> wind_dir wind_speed wind_gust units
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
      set magic [expr ]
      set rprt_wind_dir [lindex {N NE E SE S SW W NW N} $magic]
    } else {
      set rprt_wind_dir [mc " Variable"]
    }
    if {[scan $wind_speed %d wind_speed] != 1} {
      continue
    }
    set rprt_wind_speed [expr ]
    append rprt_wind [mc "Wind: Speed: %1\$sKm/h Direction: %2\$s " $rprt_wind_speed $rprt_wind_dir]
    if {[scan $wind_gust %d wind_gust] > 0} {
      set rprt_wind_gust [expr ]
      append rprt_wind [mc "Gusts: %sKm/h " $rprt_wind_gust]
    }
    append report $rprt_wind
  }  { #temperature and dewpoint
    if {[string length $token] == 5} {
      set temptoken [string map {M -} $token]
      set rprt_temp_val [lindex [split $temptoken "/"] 0]
      set rprt_temp_dwp [lindex [split $temptoken "/"] 1]
      set rprt_temp [mc "Temperature: %1\$s°C Dewpoint: %2\$s°C. " $rprt_temp_val $rprt_temp_dwp]
      append report $rprt_temp
    }
  } {[AQ]\d} { #pressure
    set rprt_pres_type [string index $token 0]
    set rprt_pres_val [string trim $token ]
    switch -- $rprt_pres_type {
       {
        append report [mc "Pressure: %shPa " $rprt_pres_val]
      }  {
        #TODO add units to this value
        append report [mc "Pressure: %s " $rprt_pres_val]
      } default {
        append report [mc "Pressure: No available. "]
      }
    }
  } {^(\d)$} { #visibility
    set visib [expr ]
    append report [mc "Visibility: %sKm " $visib]
  } {^[A-Z](\d)?([A-Z])?|CAVOK|VCRA$} { #sky
          variable sky_cond
          if {[info exists sky_cond([string range $token 0 2])]} {
            set cond $sky_cond([string range $token 0 2])
            set rprt_sky_cond [lrange $cond 0 end]
            set rprt_sky_clouds [string range $token 3 5]
            append report [mc "Sky: %s " $rprt_sky_cond]
            if {[string is integer -strict $rprt_sky_clouds] } {
              set rprt_sky_clouds_height [expr ]
              append report [mc "%1\$s at %2\$sm " $rprt_sky_cond $rprt_sky_clouds_height]
            }
          }
        } {^[+-]?([A-Z])+$} { #phen
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
  }  { #remarks
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