#!W:/perl/bin/perl.exe

# CGI Perl-Requesthandler, der mit der Kontopflegeseite kommuniziert

use strict;
use warnings;
no strict 'refs';

use CsvTableMaintainer;
use MiniJSON;


my $queryString = $ENV{"QUERY_STRING"} 
   || "action=get_all";  # Für standalone Testausführungen
   
my ($action) = ($queryString =~ /action=(\w+)/);


my $tableMaintainer = CsvTableMaintainer::new( file=>"konto.dat" );

print "Content-Type:text/plain\n\n";


# Im Queryparameter übergebene Aktion ausführen
print &{$action}() if $action;

#-----------------------------------------------------------------------
# Action "get_all" - Tabelle einlesen und an den Client übergeben
#-----------------------------------------------------------------------
sub get_all {
  my $buchungen = 
       csv_rows_to_json( 
         $tableMaintainer->get_rows());
  my $user = get_logon_user();
  return qq({ buchungen:$buchungen, user:"$user" }); 
  }


#-----------------------------------------------------------------------
# Action "save" - vom Benutzer getätigte Änderungen übernehmen
#-----------------------------------------------------------------------
sub save {
  
  my ($httpBody, $changed) = ("",{});
    
# HTTP-Body des Requests einlesen  
  foreach (<STDIN>) {
    $httpBody .= $_;
    }

# Der Request-Body ist ein JSON-Hash mit den geänderten Zeilen
  $changed = eval_json_hash( $httpBody );

# Änderungen übernehmen
  $tableMaintainer->update_rows( $changed ); 
  
# Abspeichern  
  $tableMaintainer->save( ); 
    
# Komplette HTML-Tabelle neu berechnen und als Name:Wert-Paar übergeben   
  my $buchungen = csv_rows_to_json( $tableMaintainer->get_rows("buchungen") );

  return qq({ buchungen:$buchungen, msg:"Die Daten wurden gesichert"});
  
  }
  
#-----------------------------------------------------------------------
# In dieser Subroutine könnte der User, 
# mit dem die HTTP-Anmeldung erfolgt ist, ausgelesen werden  
#-----------------------------------------------------------------------
 sub get_logon_user() {
  return "petra";
  } 
  
