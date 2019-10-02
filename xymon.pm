################################################################################
#  B I G   B R O T H E R
#
#  Name:        bbrother.pm
#  Desription:  Common Perl Module provideing xymon functions
#
#  History:
#    15.06.2018 AM complete new version,  supporting only xymon
#
################################################################################

################################################################################
#   P E R L   R E S T R I C T I O N S
################################################################################
package xymon ;

use strict ;
#use warnings;

################################################################################
#   S T A N D A R D   L I B R A R I E S
################################################################################
require Exporter ;

################################################################################
#   G L O B A L S
################################################################################
use vars qw(  @ISA    @EXPORT  @EXPORT_OK $VERSION );

$VERSION   = "3.00" ;
@ISA       = qw( Exporter) ;
@EXPORT    = qw( writeMsg importEnv) ;

my $IMPORTED = 0 ;

################################################################################
#   F U N C T I O N S
################################################################################
sub importEnv
{
  return if $IMPORTED == 1 ;
  $IMPORTED = 1 ;

  my $file = "/home/xymon/client/etc/xymonclient.cfg" ;

  die "can't open $file" unless open CFG, $file;

  foreach my $line (<CFG>)
  {
    chomp $line;
    next if $line =~ /^\s*#/ ;
    next if $line =~ /^\s*$/ ;
    $line =~ /^\s*(\w+)=\"(.*?)\"/ ;
    my $key = $1 ;
    my $val = $2 ;

    next if exists $ENV{$key} ;

    if( $val =~ /\$/ )
    {   
      $val =~ /\$(\w+)/ ;
      my $subKey = $1 ;
      my $subVal = $ENV{$subKey} ;
      $val =~ s/\$$subKey/$subVal/ ;
    }   
    $ENV{$key}="$val";
  }
  close CFG ;
}

################################################################################
#   W R I T E   M E S S A G E
################################################################################
sub writeMsg
{
  importEnv unless $IMPORTED == 1 ;

  my $msg     = $_[0] ;
  my $color   = $_[1] ;
  my $machine = $_[2] ;
  my $test    = $_[3] ;

  my $XYMON  = $ENV{XYMON} ;
  my $XYMSRV = $ENV{XYMSRV};

  my $tm      =  scalar(localtime) ;

#/home/xymon/client/bin/xymon lxdbsp05 --merge "status+5 ADMLT01.dlq green Fri Jun 15 15:55:52 2018"

  open( PROC,
        "|$XYMON $XYMSRV --merge \"status $machine\.$test $color $tm\" ");
  print PROC "$msg\n" ;
  close PROC;
}

################################################################################
#   D E F A U L T   R E T U R N   C O D E
################################################################################
1 ;

