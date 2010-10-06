package MiniJSON;

# Minimalistischer JSON-Layer für das CSV-Pflegebeispiel

use base qw (Exporter);

our @EXPORT = qw(eval_json_hash csv_rows_to_json);


#-----------------------------------------------------------------------
# Array von csv-artigen Zeilen in JSON Array of Arrays wandeln
#-----------------------------------------------------------------------
sub csv_rows_to_json {
  my ($rows,$num_cols) = @_;
  my ($line,@cells,$row,$result);
  $result = "";
  foreach $line (@$rows) {
    chomp $line;
    next if $line =~ /^\s*#/ or $line =~ /^\s*$/;    
    $line =~ s/\\/\\\\/g;
    $line =~ s/(['"])/\\$1/g;
    @cells = split ";", $line, $num_cols;
    $row = join ',', map { qq("$_") } @cells;         
    $result .= "," if $result;
    $result .= qq([$row]);    
    }
  return qq([$result]);
  }  
   
#-----------------------------------------------------------------------
#  Vereinfachte Extraktion eines JSON-Hashs
#-----------------------------------------------------------------------
sub eval_json_hash {
  
  my $text = shift;
  my $hash;
  
# Alle Doppelpunkte, auf die ein Anführungszeichen folgt, ersetzen durch =>
  $text =~ s/:(?=\s*['"])/=>/g;
 
  $hash = eval($text);
 
# Die Maskierung der Anführungszeichen im Text entfernen 
  foreach my $key (keys %$hash) {
    $hash->{$key} =~ s/\\(['"])/$1/g;
    }
 
  return $hash;
  }  
  
  