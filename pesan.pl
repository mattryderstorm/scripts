#!/usr/bin/perl

# 2005-01-18 - ganti "\t" jadi "  " dan alamat email
# 040327 - by default look for pesan.dat in $Bin
# 020413

$debug = 0;
$stdout_instead = 1;
#($day_now,$mon_now,$year_now)=(29,3,2003);

use FindBin '$Bin';
use Mail::Sendmail;

if (-f "/etc/.builder") {
  $from = 'pesan-steven-noreply@steven.rh73vm.builder.localdomain';
  $to = 'steven@steven.rh73vm.builder.localdomain';
} else {
  $from = 'pesan-steven-noreply@sloki.com';
  $to = 'steven@sloki.com';
}

@dom = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
if (!$day_now or !$mon_now or !$year_now) {
  ($day_now,$mon_now,$year_now) = (localtime)[3,4,5]; $mon_now++; $year_now += 1900;
}
$ndays_now = calc_ndays($day_now,$mon_now,$year_now);
@matches = ();

if (@ARGV == 0 && (-f "$Bin/pesan.dat")) { push @ARGV, "$Bin/pesan.dat" }

while(<>){
  next unless /\S/;
  next if /^[#;]/;
  do { warn "Line $.: not match!: $_"; next; } unless /^([JUT]) (\d\d)(\d\d)(\d\d\d\d) ("[^"]+"|'[^']+')(?: (\d+) (\d+))?\s*$/;
  ($t, $mday, $mon, $year, $msg, $a, $b) = ($1, $2, $3, $4, substr($5,1,length($5)-2), $6, $7);
  warn "Line $.: must have a and b: $_" if $t ne 'U' and (!defined($a) or !defined($b));
  $a = 0 if !defined($a); $b = 0 if !defined($b); do{$a=7;$b=1} if $t eq 'U';
  if ($t ne 'J') { @y = ($year_now-1,$year_now,$year_now+1) } else { @y = $year }
  
  $done=0;
  L:
  for $y (@y) {
    last if $done;
    $ndays = calc_ndays($mday,$mon,$y);
    print "DEBUG: $t, $mday, $mon, $year|$year2, $msg, $a, $b, $ndays_now ? ${\($ndays-$a)}-${\($ndays+$b)}" if $debug;

    if (($ndays_now >= $ndays-$a) and ($ndays_now <= $ndays+$b)) {
      $done++;
      print " hit!" if $debug;
      $msg1 = $ndays_now == $ndays ? "hari ini" :
              (abs($ndays_now-$ndays) . " hari " . ($ndays_now > $ndays ? "yl":"lagi"));
      $msg2 = $t eq 'U' ? "$msg ultah yang ke-".($year_now-$year) : $msg;
      
      push @matches, [$ndays-$ndays_now, "$msg1: $msg2 ($mday-$mon-$y)\n"];
    }
    print "\n" if $debug;
  }
}
  
if (@matches) {
  $body = join "", map {$_->[1]} sort {$a->[0] <=> $b->[0]} @matches;
} else {
  $body = "";
}

exit unless $body;

if ($stdout_instead) {
  print $body;
} else {
  sendmail(
    subject => "Pesan hari ini ($day_now-$mon_now-$year_now)",
    from => $from,
    to => $to,
    message => $body
  ) or die "Error sending mail: $Mail::Sendmail::error\n";
}

sub calc_ndays {
  my ($d,$m,$y)=@_;
  my $c;
  
  $dom[1] = $y%4==0 ? 29:28;
  $c=0;
  for(0..$m-2){$c+=$dom[$_]}
  int(($y-1905)*365.25)+($d-1)+$c;
}
