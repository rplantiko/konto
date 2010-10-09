package CsvTableMaintainer;

# Eine CSV-Datei verwalten 

use strict;
use warnings;

sub new {
  my %args = @_;
  my $self = { cols=>5,        # Zahl der Spalten, in die die CSV-Zeile aufgespalten wird 
               prefix=>"buch", # Nur Zeilen mit diesem Key-Präfix werden berücksichtigt
               rows=>[],       # Bild der Datei als Zeilen-Array
               index=>{}       # Index-Hash für die Keys
               };
               
  foreach my $key (keys %args) {
    $self->{$key} = $args{$key};    
    }
  die "Bitte Pflegedatei angeben" unless $self->{file};
  bless $self;
  $self->read_rows();
  return $self;
  }


#-----------------------------------------------------------------------
# Änderungen am Bild der Datei (dem Array @rows) durchführen
#-----------------------------------------------------------------------
sub update_rows {
  
  my ($self,$changed) = @_;
      
  my ($key,$line,%id,$maxrow);
  
  $maxrow = 0;
  foreach $key (keys %{$self->{index}}) {
    if ($key =~ /$self->{prefix}(\d+)/o) {
      $maxrow = $1 if ($maxrow < $1); 
      }
    }
    
  foreach $key (keys %$changed) {    
    $line = $changed->{$key};    
    if ($line eq "deleted") {
      $self->delete_row( $key );
      }
    elsif ($key =~ /^new/) {
      $maxrow++;
      $id{$key} = $self->{prefix} . $maxrow;
      $self->insert_row( $id{$key}, $line );      
      }  
    else {
      $self->change_row( $key, $line );
      }    
    }  
  }  


#-----------------------------------------------------------------------
# Delete-Operationen ausführen (im Speicher)
#-----------------------------------------------------------------------
sub delete_row {
  my ($self,$key) =  @_;
  my $i = $self->{index}->{$key};
  if ($i) {
    delete $self->{rows}->[$i];
    delete $self->{index}->{$key};
    }
  }
  
#-----------------------------------------------------------------------
# Insert-Operationen ausführen (im Speicher)
#-----------------------------------------------------------------------
sub insert_row {
  my ($self,$new_key,$line) = @_;
  push @{$self->{rows}}, $new_key . ";" . $line;
  $self->{index}->{$new_key} = $#{$self->{rows}};
  }
  
#-----------------------------------------------------------------------
# Update-Operationen ausführen (im Speicher)
#-----------------------------------------------------------------------
sub change_row {
  my ($self,$key,$line) = @_;
  my $i = $self->{index}->{$key};
  if ($i) {
    $self->{rows}->[$i] = $key . ";" . $line;
    }
  }    


#-----------------------------------------------------------------------
# Das File mit den Buchungszeilen einlesen
#-----------------------------------------------------------------------
sub read_rows {
  my $self = shift;
  my $rows = $self->{rows};
  open KONTO, "<$self->{file}" or die "Kann Datei $self->{file} nicht zum Lesen öffnen";
  foreach (<KONTO>) {
    chomp;
    push @$rows,$_;
    }
  close KONTO; 
  $self->build_index();
  return $rows;
  }

#-----------------------------------------------------------------------
# Das File mit den Buchungszeilen abspeichern
#-----------------------------------------------------------------------
sub save {
  my $self = shift;
  my $row;
  open KONTO, ">$self->{file}" or die "Kann Datei $self->{file} nicht zum Schreiben öffnen";
  foreach $row (@{$self->{rows}}) {
    print KONTO $row . "\n" if $row;
    }
  close KONTO;
  }


#-----------------------------------------------------------------------
# Einen Index (Hash) "ID -> Zeilennummer im Array" aufbauen
#-----------------------------------------------------------------------
sub build_index {
  
  my $self = shift;
  my ($row,$key,$index);
  
  my $idx  = $self->{index};

  $index = 0;
  foreach my $row (@{$self->{rows}}) {
    ($key) = ($row =~ /^(\w+)/); 
    $idx->{$key} = $index if $key;  
    $index++;
    } 
  
  return $idx;
  
  }
  
#-----------------------------------------------------------------------
# Die Zeilen mit passendem Key-Präfix zurückgeben 
#-----------------------------------------------------------------------
sub get_rows {
  my $self = shift;
  my (@rows,$row);
  
  foreach $row (@{$self->{rows}}) {
    next unless $row =~ /^$self->{prefix}(\d+)/o;
    push @rows, $row;    
    }
  
  return \@rows;
  }

1;