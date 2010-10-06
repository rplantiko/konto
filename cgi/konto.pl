#!W:/perl/bin/perl.exe

# CGI Perl-Requesthandler, der mit der Kontopflegeseite kommuniziert

use strict;
use warnings;
no strict 'refs';

use CsvTableMaintainer;
use MiniJSON;


my $queryString = $ENV{"QUERY_STRING"} 
   || "action=get_all";  # F�r standalone Testausf�hrungen
   
my ($action) = ($queryString =~ /action=(\w+)/);


my $tableMaintainer = CsvTableMaintainer::new( file=>"konto.dat" );

print "Content-Type:text/plain\n\n";


# Im Queryparameter �bergebene Aktion ausf�hren
print &{$action}() if $action;

#-----------------------------------------------------------------------
# Action "get_all" - Tabelle einlesen und an den Client �bergeben
#-----------------------------------------------------------------------
sub get_all {
  my $buchungen = 
       csv_rows_to_json( 
         $tableMaintainer->get_rows());
  my $user = get_logon_user();
  return qq({ buchungen:$buchungen, user:"$user" }); 
  }


#-----------------------------------------------------------------------
# Action "save" - vom Benutzer get�tigte �nderungen �bernehmen
#-----------------------------------------------------------------------
sub save {
  
  my ($httpBody, $changed) = ("",{});
    
# HTTP-Body des Requests einlesen  
  foreach (<STDIN>) {
    $httpBody .= $_;
    }

# Der Request-Body ist ein JSON-Hash mit den ge�nderten Zeilen
  $changed = eval_json_hash( $httpBody );

# �nderungen �bernehmen
  $tableMaintainer->update_rows( $changed ); 
  
# Abspeichern  
  $tableMaintainer->save( ); 
    
# Komplette HTML-Tabelle neu berechnen und als Name:Wert-Paar �bergeben   
  my $buchungen = csv_rows_to_json( $tableMaintainer->get_rows("buchungen") );

  return qq({ buchungen:$buchungen, msg:"Die Daten wurden gesichert"});
  
  }
  
#-----------------------------------------------------------------------
# In dieser Subroutine k�nnte der User, 
# mit dem die HTTP-Anmeldung erfolgt ist, ausgelesen werden  
#-----------------------------------------------------------------------
 sub get_logon_user() {
  return "petra";
  } 
  
