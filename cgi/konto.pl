#!W:/perl/bin/perl.exe

# CGI Perl-Requesthandler, der mit der Kontopflegeseite kommuniziert

use strict;
use warnings;
no strict 'refs';

use CsvTableMaintainer;
use MiniJSON;


my $queryString = $ENV{"QUERY_STRING"} 
   || "action=restore";  # Für standalone Testausführungen
   
my ($action) = ($queryString =~ /action=(\w+)/);


my $tableMaintainer = CsvTableMaintainer::new( file=>"konto.dat" );

print "Content-Type:text/plain\n\n";


# Im Queryparameter übergebene Aktion ausführen
print &$action() if $action;

#-----------------------------------------------------------------------
# Action "get_all" - Tabelle einlesen und an den Client übergeben
# Eventuell mit Message, die als Parameter übergeben wird
#-----------------------------------------------------------------------
sub get_all {
  my $msg = shift || "";
  my $buchungen = 
       csv_rows_to_json( 
         $tableMaintainer->get_rows());
  my $user = get_logon_user();
  return qq({ buchungen:$buchungen, user:"$user", msg:"$msg" }); 
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
    
# Nun wie bei get_all fortfahren
  return get_all( "Die Daten wurden gesichert");
  
  }
  
#-----------------------------------------------------------------------
# In dieser Subroutine könnte der User, 
# mit dem die HTTP-Anmeldung erfolgt ist, ausgelesen werden  
#-----------------------------------------------------------------------
 sub get_logon_user() {
  return "petra";
  } 
  
#-----------------------------------------------------------------------
# Nur für Tests: Aktion restore ersetzt Kontodatei durch Vorlage
#----------------------------------------------------------------------- 
sub restore() {
  use File::Copy;
  copy("template.dat", "konto.dat") or return qq(msg:"$!");
  $tableMaintainer = CsvTableMaintainer::new( file=>"konto.dat" );
  return get_all("Die Testdaten wurden zurückgesetzt");
  }