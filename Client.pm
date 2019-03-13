#
#===============================================================================
#
#         FILE:  AMS/Client.pm
#
#  DESCRIPTION:  A Common Client Class.
#
#       AUTHOR:  Anatolii A. Apanasiuk <a3three@gmail.com>, 
#      COMPANY:  Private
#      VERSION:  1.0
#      CREATED:  11/28/2011 04:50:22 PM
#     REVISION:  ---
#===============================================================================
package AMS::Client; 
use Moose; 

use Log::Log4perl qw(get_logger :easy :levels);
use Config::IniFiles;
use XML::LibXML;
use XML::Simple; 
use Data::Dumper;
use Carp;

use Module::Load qw(load);
use WS::Client; 
use Util::Logger;

our $AUTOLOAD;

has RootDir         => ( is => 'rw', isa => 'Str' );
has ConfigFile      => ( is => 'rw', isa => 'Str' );
has Config          => ( is => 'rw', isa => 'Config::IniFiles' );

has BaseURL         => ( is => 'rw', isa => 'Str', required => 1 ); 
has Protocol        => ( is => 'rw', isa => 'Str', default => "JSON" ); 

has WantObject      => ( is => 'rw', isa => 'Bool', default => 0 ); 
has Authentication  => ( is => 'rw', isa => 'Str' ); 

has Module          => ( is => 'rw', isa => 'Str' );
has Parent          => ( is => 'rw', isa => 'Object' );
has Clients         => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

has Result          => ( is => 'rw', isa => 'HashRef' ); 
has Endpoint        => ( is => 'rw', isa => 'Str' ); 
has SendMethod      => ( is => 'rw', isa => 'Bool' );

#==============================================================================
=head1 NAME

AMS::Client

=head1 SYNOPSIS

use AMS::Client;

my $client = AMS::Client->new
  (BaseURL => "http://SomeServer:SomePort
   Authentication => "SomeAuthStuff", 
   Module => "Module Name", # Not essential anymore.
   WantObject => "[0|1]"
    );

my $t = $client->Client();
or
my $t = $client-><Module>(); 

my $response = $t-><ClientCommand>(<options>); 
And other Client Calls.

if ( ! defined $response || ! $response->isOK ) { 
   die "Invalid Response";
} 

my  $result = $response->Result; 

=cut

=head1 DESCRIPTION

The Client module is the API provided for general script use.

Nornmally these scripts will sit behind a service endpoint.

When they get triggered the the scripts will be called 
with TaskId and Delegation and Possibly endpoint.

Then the following sequence can occur.

use AMS::Client; 

my $client = AMS::Client->new( BaseURL => "wibble", "Module" => "AMS::Task::Client", WantObject => 1  ); 

my $r = $client->GetTask(TaskId => $TaskId)
if ( defined($r) && $r->isOK ) { 	

  $task= $client->Result->{'Task'};

} elsif ( defined($r) ) { 

  die ("Get Task Failed: " . $r->Code . ":" .$r->Message . " -- " . $r->State); 	

} else { 

  die ("Get Task Failed:"); 	

} 

=cut
#==============================================================================


#==============================================================================
=head2 BUILDARGS

This subroutine occurs before the constructor, It should derive any missing
information. Thus can use the 'required' field in the attribute definition.

=cut
#==============================================================================

around 'BUILDARGS' => sub { 
  my $orig = shift; 
  my $class = shift; 
	
  my %args = (ref $_[0] eq 'HASH') ? %{ $_[0] } : @_ ;

  if ( ! defined($args{'RootDir'}) ) {
    if ( ! defined($ENV{'ROOT_DIR'}) ) {

      my $pkg = __PACKAGE__;

      my $pkg_file = $pkg;
      $pkg_file =~ s/::/\//g;
      $pkg_file .= ".pm";

      my $root_dir = $INC{$pkg_file};
      $root_dir =~ s{/lib/$pkg_file}{};
      $ENV{'ROOT_DIR'} = $root_dir;

    }
    $args{'RootDir'} = $ENV{'ROOT_DIR'};
  }

  if ( ! defined($args{'Authentication'}) && defined($ENV{'AAL_AUTHENTICATION'}) ) { 
    $args{'Authentication'} = $ENV{'AAL_AUTHENTICATION'};
  } 

  my $cfg = $args{'Config'} || Config::IniFiles->new("-file" => $args{'RootDir'}."/conf/AALAgentd.conf", "-default" => "WebService");

  $args{'Config'} = $cfg if ( ! defined($args{'Config'}) ); 
  $args{'Protocol'} = "JSON" if ( ! defined($args{'Protocol'}) );

  return $class->$orig(%args);

};

#==============================================================================
=head2 getClient(module, [module_base dir])

Loads the client class;

=cut
#==============================================================================

sub getClient {
  my ($self, $module, $module_wspath, $agent_dir, $client_class) = @_;

  $module        ||= $self->Module;
  return undef if (!defined($module) );

  if (  defined($self->Clients->{$module}) ) { 
    return $self->Clients->{$module};
  } 

  my $log = $self->get_logger();
  my $cfg = $self->Config; 

  my $base_url = $self->BaseURL;
  my $protocol = $self->Protocol;
  my $root_dir = $self->RootDir; 
  my $endpoint = $self->Endpoint;

  my ($aal_root) = ( $root_dir =~ m{(.+)/(Services|AALAgent)($|/.*)} ); 

  my $module_sect = "Module ${module}";

  $module_wspath ||= $cfg->val($module_sect, "URLPath") || $module;
  $agent_dir     ||= $cfg->val($module_sect, "AgentDir") || "";
  $client_class  ||= $cfg->val($module_sect, "ClientClass") || "AMS::${module}::Client" ;
  $endpoint      ||= $cfg->val($module_sect, "Endpoint") || undef ;

  $log->info("Client Class: $client_class");
  $log->debug("URLPath: $module_wspath");
  $log->debug("AAL Root: $aal_root");
  $log->debug("Module Section: $module_sect");

  $endpoint  ||= $base_url
               . ( $base_url =~ /.*\/$/ ? "" : "/" ) 
               . $self->Protocol 
               . "/" 
               . $module_wspath . ".asmx"; 

  $log->debug("Agent Dir: $agent_dir");

  # Root Dir might be relative to another location.
  my $full_agent_dir; 

  if ( -d $aal_root."/AALAgent" ) { 
    $full_agent_dir = ( $agent_dir eq "" ? $aal_root."/AALAgent" : $aal_root."/".$agent_dir );
  } else { 
    $full_agent_dir = ( $agent_dir eq "" ? $aal_root."/AALAgent" : $root_dir."/".$agent_dir );
  }

  $log->debug("Full Agent Dir: $full_agent_dir");

  if ( $self->loadModule($client_class, $full_agent_dir) ) { 
    my %args = ( 
                RootDir => $root_dir, 
                Protocol => $protocol, 
                WantObject => $self->WantObject || 0,
                Config  => $cfg
    );
    my $inst = $client_class->new(Endpoint => $endpoint, %args);
    $self->Clients->{$module} = $inst;
    return $inst; 

  } else { 
    return undef; 
  }

}

#AKA:
*Client = *getClient;
 
#==============================================================================
=head2 loadModule

Loads the requested Module located at module path $AGENT_DIR.

=cut
#==============================================================================

sub loadModule {
  my ($self, $module_class, $AGENT_DIR) = @_;

  my $log=$self->get_logger();

  my $agent_lib_dir = $AGENT_DIR . "/lib";
  my $module_file = $module_class . ".pm";

  $module_file =~ s/::/\//g;
  $module_file = $agent_lib_dir ."/".$module_file;

  $log->debug("Agent Dir: $AGENT_DIR");
  $log->debug("Module Class: $module_class");
  $log->debug("Module File: $module_file");

  if ( ! -d $agent_lib_dir ) {
    $log->warn("No Agent Lib Dir: $agent_lib_dir -- Skipping");
    return 0;
  }

  if ( ! -f "${module_file}" ) {
      $log->warn("No Class File: $module_file -- Skipping");
      return 0;
  }

  if ( $agent_lib_dir ~~ @INC )  {
    $log->debug("Have Agent lib dir already defined: $agent_lib_dir");
  } else {
    $log->debug("Adding Agent lib dir: $agent_lib_dir");
    unshift @INC, $agent_lib_dir;
  }

  $log->info(Dumper(\@INC)) if ( $log->is_debug() );

  eval {
   load $module_class if ( ! defined($INC{$module_file}) );
  };

  if ( $@ ) {
    $log->error("Got Module Loading Error: " . $@ );
    $log->warn("Skipping");
    return 0; 
  }
  return 1;
}

#==============================================================================
=head2 genOptions

Returns the specification for the options. This only supports name/value
settings, not complex data structures.

=cut
#==============================================================================

sub genOptions {
  my ($self, $method) = @_;

  die "No Client Instance Configured" if ( ! defined($self->Client) );
  die "No Client Definition Defined"  if ( ! defined($self->Client->Definition) );

  my $def = $self->Client->Definition;
  my ($command_def) = grep { $_->{'Name'} eq $method } @{ $def->{'Methods'} }; 
 
  die "No Method my name $method" if ( !defined($command_def) ); 

  my @the_options =  map { $_->{'Name'} ."=s" } 
                    grep { ( defined($_->{'type'}) && $_->{'type'} eq "string" )
                        || ( defined($_->{'Type'}) && $_->{'Type'} eq "string" ) 
                         } @{ $command_def->{'Request'} };
  return @the_options; 
} 

#==============================================================================
=head2 getRequired

Returns an array of required options. 

=cut
#==============================================================================

sub getRequired {
  my ($self, $method) = @_;

  die "No Client Instance Configured" if ( ! defined($self->Client) );
  die "No Client Definition Defined" if ( ! defined($self->Client->Definition) );

  my $def = $self->Client->Definition;
  my ($command_def) = grep { $_->{'Name'} eq $method } @{ $def->{'Methods'} }; 
 
  die "No Method my name $method" if ( !defined($command_def) ); 

  my @req_options = map { $_->{'Name'} } 
                   grep { (  ( defined($_->{'type'}) && $_->{'type'} eq "string" )
                          || ( defined($_->{'Type'}) && $_->{'Type'} eq "string" ) 
                          ) 
                       && (  ( defined($_->{'required'}) && $_->{'required'} == 1 )
                          || ( defined($_->{'Required'}) && $_->{'Required'} == 1 ) 
                          ) 
                        } @{ $command_def->{'Request'} };
  return @req_options; 
} 

#==============================================================================
=head2 AUTOLOAD

Returns an array of required options. 

=cut
#==============================================================================

sub AUTOLOAD { 
  my $self = shift;
 
  my $cfg = $self->Config;
  my $log = $self->get_logger();

  my $module = $AUTOLOAD; 
  $log->debug("Loading Module: $module");
  
  $module =~ s/.*://;

  return $self->getClient($module);

}

__PACKAGE__->meta->make_immutable;
1;