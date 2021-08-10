################################################################################
#  mqsc 
#
#  Name:        mqsc.pm
#  Desription:  Common Perl Module providing functions on qmgr object
#
#  History:
#    15.06.2018 AM complete new version,  supporting only xymon
#
################################################################################

#BEGIN
#{
#  push @INC, $ENV{HOME}.'/monitor/lib' ;
#}

################################################################################
#   P E R L   R E S T R I C T I O N S
################################################################################
package mqsc ;

use strict ;
use warnings;

################################################################################
#   S T A N D A R D   L I B R A R I E S
################################################################################
require Exporter ;

use Time::HiRes qw(usleep nanosleep);
use FileHandle ;
use IPC::Open2 ;
use POSIX ":sys_wait_h" ;

################################################################################
#   G L O B A L S
################################################################################
use vars qw(  @ISA    @EXPORT  @EXPORT_OK $VERSION );

$VERSION   = "5.00" ;
@ISA       = qw( Exporter) ;
@EXPORT    = qw( connect parseMqsc ) ;

my $IMPORTED = 0 ;

################################################################################
#   F U N C T I O N S
################################################################################

################################################################################
# connect qmgr
################################################################################
sub connect
{
  my $runmqsc = $_[0];
  my $qmgr    = $_[1];
  my $rd      = $_[2]; # optional attribute
  my $wr      = $_[3]; # optional attribute

  $qmgr = '' unless defined $qmgr ;
  $rd=FileHandle->new() unless defined $rd; # create file handles if they 
  $wr=FileHandle->new() unless defined $wr; # haven't constructed earlier

  my $exitCode ;  # 00: MQSC command file processed successfully
                  # 10: MQSC command file processed with errors; report
                  #     contains reasons for failing commands
                  # 20:  Error; MQSC command file not run

  my $platform ;

  # --------------------------------------------------------
  # start runmqsc 
  # --------------------------------------------------------
  my $pid =  open2( $rd, $wr, "$runmqsc $qmgr" );
  usleep 1000000 ;       # give runmqsc a chance

  if( $pid == waitpid $pid, &WNOHANG )
  {
    print "end\n" ;
    $exitCode = $? >> 8 ;
    close $rd ;
    close $wr ;
    $pid = 0 ;
    return ( $pid, $rd, $wr, $exitCode, $platform ) ;
  }

  print $wr "display qmgr platform\n" ;

  while( my $line = <$rd> )
  {
    chomp $line ;
    next unless $line =~ /\s+PLATFORM\((\w+)\)\s*$/ ;
    $platform = $1 ;
    last if $platform eq 'UNIX' ;
    next;
  }
}

################################################################################
# parse mqsc
################################################################################
sub parseMqsc
{
  my $rd = $_[0] ;  # mqsc read pipe
  my $os = $_[1] ;  # operating system of the queue manager

  my $_obj  ;       # hash ref for return
  my $obj   ;       # object name
  my $_objRef ;     # object array

  while( my $line=<$rd> )
  {
    chomp $line;                         #
    next if $line =~ /^\s*$/ ;           #
                                         #
    if( $line =~ /(AMQ\d{4})\w:/ )       #
    {                                    #
      my $amq = $1;                      #
      if( $amq eq 'AMQ8145' ||           # Connection broken.
          $amq eq 'AMQ8156' ||           # queue manager quiescing
          $amq eq 'AMQ8416'  )           # Time Out
      {                                  #
        return undef ;                   #
      }                                  #
      last         if $amq eq 'AMQ8415'; # Ping Queue Manager command complete.
      die $line    if $amq eq 'AMQ8569'; # Error in filter specification
      die $line    if $amq eq 'AMQ8147'; # WebSphere MQ object %s not found.
      if( $amq eq 'AMQ8147')             # WebSphere MQ object %s not found.
      {                                  #
        warn "$line\n" ;                 #
        next;                            #
      }                                  #
      if( $amq eq 'AMQ8409' ||           # Display Queue details.   AMQ8407
          $amq eq 'AMQ8417' ||           # Display Channel Status details.
          $amq eq 'AMQ8450' ||           # Display queue status details.
          $amq eq 'AMQ8414' ||           # Display Channel details.
          $amq eq 'AMQ8420'  )           # Channel Status not found ???
      {                                  #
        $obj = undef;                    #
        next;                            #
      }                                  #
      warn "uknown MQ reason line\n";    #
    }                                    #
                                         #
    next if $line =~ /^\s*$/ ;           # ignore empty lines
                                         #
    # ------------------------------------------------------
    # new object found
    # ------------------------------------------------------
    if( $line =~ s/^CSQM4\d{2}I\s+       # object or status type message
                    (\w+)\s+//x    )     # queue manager name
    #   $line =~ /(AMQ\d{4}):/         ) # AMQ message missing for Unix
    {                                    #
      $obj = undef;                      #
    }                                    #
                                         #
    # ------------------------------------------------------
    # handle non mqsc output
    # ------------------------------------------------------
                                         #
    if( $os eq 'MVS' )                   #
    {                                    #
      next if $line =~ /^CSQN205I\s*/;   # command processor return code
                                         # first line for ZOS
      if( $line =~ /^CSQ9\d{3}\w\s+/ )   # error handling missing
      {                                  # for messages  beside CSQ9022I
        last if $line =~ /^CSQ9022I\s+/; # NORMAL COMPLETION
        last ;                           #
      }                                  #
    }                                    #
                                         #
    # ------------------------------------------------------
    # handle mqsc output
    # ------------------------------------------------------
    while( $line =~ s/^\s*(\w+)(\((.*?)\))?\s*// )
    {                                    #
      my $key   = $1 ;                   #
      my $value = $3 ;                   #
      unless( defined $obj )             #
      {                                  #
      # logfdc( @_ ) unless defined $value ;
        $obj = $value ;                  #
        $_objRef = &newHash() ;          #
        push @{$_obj->{$obj}}, $_objRef; #
        next ;                           #
      }                                  #
      $_objRef = ${$_obj->{$obj}}[-1] if exists $_obj->{$obj} ;
      $_objRef->{$key} = $value ;        #
    }                                    #
  }                                      #
  return $_obj ;
}

################################################################################
# create a hash as a reference
################################################################################
sub newHash
{
  my %h ;
  return \%h ;
}

################################################################################
#   D E F A U L T   R E T U R N   C O D E
################################################################################
1 ;

