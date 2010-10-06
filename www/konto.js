var detailRow; // Verweist auf HTML-Element TR der im Detailbereich dargestellten Zeile
var backendURL = "/cgi-bin/konto.pl"; // Verweist auf den Requestbehandler f�r die Kontopflege

function doOnLoad() {  

// --- Formulardaten zur�cksetzen, Ladezustand anzeigen
  resetDetailForm();
  $("msg").update("");

  sendRequest( "get_all", { onComplete:updatePage } );  

// --- Die statisch definierten Clickbehandler registrieren    
  $("take").observe("click",   onclick_takeDetails );
  $("cancel").observe("click", onclick_cancel );
  $("save").observe("click",   onclick_save );
  $("new").observe("click",    onclick_newEntry );    
  
  }

// --- Nach R�ckkehr eines Ajax-Requests: Seitenteile aktualisieren
function updatePage(transport) {
  var id, newCode;
  newCode = transport.responseText.evalJSON();
  for (id in newCode) {
// Entweder mit spezieller Methode, falls implementiert ...    
    if (typeof self[id+"_update"] == "function") {
      self[id+"_update"](newCode[id]);
      }
// ... oder einfach durch Austausch des HTML-Contents       
    else {
      $(id).update( newCode[id] );
      }
    }
// Ladezustand zur�cksetzen    
  $("loading").hide();
  }  
  
// --- Angemeldeten User in einen unsichtbaren <span> schreiben
function user_update( user ) {
  $("user").innerHTML = user.capitalize();
  }  

// --- Vom Server als Array of Array gesendete Buchungszeilen ins HTML �bernehmen
function buchungen_update( rows ) {
  
  var tbody = $("buchungen").down("tbody");
  tbody.update("");
  
  var controlCellCode = controlCell(); 
  
  rows.each( function(cells) {
    var rowid = cells.shift();
    var row = new Element( "tr", {id:rowid} );    
    cells.each( function(cellData, index) {    
      row.appendChild( new Element( "td", {className:"c"+(index+1)}).update(cellData) );
      });
    row.appendChild( new Element( "td", {className:"c5"} ).update(controlCellCode) );
    tbody.appendChild(row);  
    });
    
  $("buchungen").show();  

// Alle Bilder in der Buchungstabelle sind clicksensitiv  
  $$("#buchungen img").each( function( img ) {
    img.observe("click", doOnClick );    
    });
    
// Datenbankstand - Sichern ist unn�tig    
  $("save").hide();  
  
  }

// Alle Clicks auf irgendeine Kontrollikone werden durch diese Funktion behandelt
// - Die Art der Ikone wird durch die CSS-Klasse bestimmt
// - Die Funktion "onclick_<CSS-Klasse>" wird mit der angeclickten Zelle als Argument
//   aufgerufen
function doOnClick( event ) {
  var target  = event.element();
  var action  = self["onclick_"+target.className];
  action(target);
  }

// --- Click auf "Zeile �ndern" : Zeile in Formular stellen und dieses sichtbar machen
function onclick_change( target ) {
  detailRow = target.up("tr");  
  var cells = detailRow.select("td");
  $("datum").value     = cells[0].innerHTML;
  $("betrag").value    = cells[1].innerHTML;
  $("bemerkung").value = cells[3].innerHTML;  
  showDetailForm();
  }

function showDetailForm() {
  $("actions").hide(); 
  $("msg").update("");
  $("detailForm").show();
  $("betrag").focus();
  }

function today() {
  var d = new Date();
  return d.getDate() + "." + (d.getMonth()+1) + "." + d.getFullYear();
  }

function hideDetailForm() {
  $("actions").show(); 
  $("detailForm").hide();
  }

function checkForm() {
  $("msg").update("");
  $w("bemerkung betrag datum").each( function( id ) {
  if (!$F(id).match(/\S/)) {
    $(id).focus();
    throw "Bitte " + id.capitalize() + " eingeben";
    }
    });
  var betrag = $F("betrag").replace(/\s+/g,"");  
  if (!betrag.match(/^\d+(\.\d+)?$/)) {
    $("betrag").focus();
    $("betrag").select();
    throw "Betrag muss eine Zahl sein";
    }
  $("betrag").value = (betrag-0).toFixed(2);    
  }  

function showError( text ) {
  $("msg").innerHTML = '<span style="color:red">' + text + '</span>';
  }  

// --- Click auf "Zeile l�schen":
function onclick_delete( target ) {
  
  var selectedRow = target.up("tr");

// Zeilendaten ggf. aus Formularbereich entfernen
  if (detailRow && (selectedRow.id == detailRow.id)) {
    resetDetailForm();
    }

// Neue Zeile kann ohne Umschweife gel�scht werden
  if (selectedRow.hasClassName("new")) {
    selectedRow.parentNode.removeChild(selectedRow);
    }     
// Schon im File bestehende Zeile: f�rs L�schen vormerken    
  else {  
  	selectedRow.addClassName("deleted");
    var controlCell = selectedRow.select("td")[4];
    controlCell.select(".delete")[0].hide();
    controlCell.select(".change")[0].hide();
    controlCell.select(".undo")[0].show();   
    }  
    
// Muss das File aktualisiert werden? Ja, dann "Sichern" anbieten  
  checkDataLoss();
  
  }

// --- Click auf "R�ckg�ngig machen"
function onclick_undo( target ) {
  var selectedRow = target.up("tr");
  
// L�schvormerkung zur�cknehmen  
  selectedRow.removeClassName("deleted");
  
// Delete und Change-Icon wieder aktivieren, undo deaktivieren   
  var controlCell = selectedRow.select("td")[4]; 
  controlCell.select(".delete")[0].show();
  controlCell.select(".change")[0].show();
  controlCell.select(".undo")[0].hide();
  
// Muss das File aktualisiert werden? Ja, dann "Sichern" anbieten  
  checkDataLoss();  
    
  }

// --- Click auf "Sichern": Ge�nderte Daten dem Server mitteilen
function onclick_save( evt ) {
  var data = extractChanges();
  sendRequest( "save", { 
    onComplete:updatePage, 
    method:"POST",
    contentType:"text/plain",
    postBody:data  } 
    );  
  resetDetailForm();
  }
  
// --- F�r die �berleitung an den Server: Alle �nderungen ermitteln  
function extractChanges() {
  var result = {};
  
  $("buchungen").select("tr").each( function(row) {
    var line ="", cellsChanged = false;
 
 // Gel�schte Zeilen bekommen den fixen Datenstring "deleted"
    if (row.hasClassName("deleted")) {
      result[row.id] = "deleted";  /* Sondercode f�r gel�schte Zeilen */  
      }
    else {
// F�r eingef�gte und ge�nderte Zeilen den Datenteil �bergeben      
      if (row.hasClassName("new")) cellsChanged = true;
      row.select("td").each( function(cell, index) {
        if (index > 3) throw $break;
        if (cell.hasClassName("changed")) cellsChanged = true;
        line += cell.innerHTML.replace(/"/g,'\\"')+";";
      });
      line = line.replace(/;$/,"");
      if (cellsChanged) {
        result[row.id] = line;
        }
      }  
    });

    
  return Object.toJSON(result);
  
  }  

// --- Formularbereich f�r Eingabe eines neuen Eintrags er�ffnen
function onclick_newEntry( evt ) {
  resetDetailForm();
  $("datum").value = today();
  showDetailForm();
  }
  

// --- Formulareingabe ohne Daten�bernahme abbrechen
function onclick_cancel( evt ) {
  resetDetailForm();
  $("msg").update("");
  hideDetailForm();
  }  

// --- Formulareingaben pr�fen und �bernehmen
function onclick_takeDetails(evt) {
  try {
    checkForm();
    if (!detailRow) detailRow = getNewRow();
    var cells = detailRow.select("td");
    cells
      .slice(0,4)
      .zip( [$("datum").value,
             $("betrag").value,
             $("user").innerHTML,
             $("bemerkung").value] )
      .each( updateCell );
    hideDetailForm();
    checkDataLoss();
    } catch(e) {
      showError(e);
      }
  }
  
// --- Eine neue Buchungszeile anlegen  
function getNewRow() {
  var id, newCounter = 0;

// N�chste freie ID der Form "newX" ermitteln, wobei X eine Zahl ist  
  $("buchungen").select("tr").each( function( row ) {
    if (row.id.match(/new(\d+)/)) {
      var counter = 1*RegExp.$1;
      newCounter = (newCounter >= counter) ? newCounter : counter;
      }
    });
  id = "new"+(newCounter+1);  

// Neue Tabellenzeile erzeugen
  var row = new Element("tr", {id:id, "class":"new"});  
  $$("#buchungen tbody")[0].appendChild( row );
  
// Zellstruktur einziehen  
  row.update( '<td class="c1"></td>' + 
              '<td class="c2"></td>' + 
              '<td class="c3 changed">' + $("user").innerHTML + '</td>' + 
              '<td class="c4"> </td>' + 
              '<td>' + controlCell() + '</td>' );
          
// Clickbehandler f�r neue Kontrollelemente registrieren              
  row.select("img").each( function( img ) {
    img.observe("click", doOnClick );    
    });
  
  return row;  
  }  

// --- Formulardaten l�schen und Formularbereich schliessen  
function resetDetailForm() {  
  $("detailForm").getElements().each( Form.Element.clear );
  hideDetailForm();
  detailRow = null;
  }

// Das HTML-Element pair[0] mit dem String pair[1] als HTML-Content f�llen
// Bei Daten�nderung CSS-Klasse "changed" setzen  
function updateCell( pair ) {

  var oldValue = pair[0].innerHTML;
  var newValue = pair[1];
  
  pair[0].innerHTML = newValue;
  
  if (oldValue != newValue ) {
    pair[0].addClassName("changed");
    }
  
  }  

// --- Save-Button nur anbieten, wenn sich Daten ge�ndert haben
function checkDataLoss() {
  $("save").style.display = dataLoss() ? "inline" : "none";
  }
  
// --- Feststellen, ob Daten ge�ndert wurden  
function dataLoss() {
  var lDataLoss = false;
  $("buchungen").select("tr").each( function(row) {
    if (row.hasClassName("deleted")) {
      lDataLoss = true;
      throw $break;
      }
    row.select("td").each( function(cell) {
      if (cell.className.match(/changed/)) {
        lDataLoss = true;
        throw $break;
        }
      });
    if (lDataLoss) throw $break;  
    });
  return lDataLoss;
  }  


// --- HTML-Code der letzten Tabellenzelle mit den Kontroll-Icons
function controlCell() {
  return '<img class="change" src="s_b_chng.gif" title="Eintrag �ndern">' +
         '<img class="delete" src="s_b_delr.gif" title="Eintrag l�schen">' +
         '<img class="undo" style="display:none" src="s_f_undo.gif" title="Eintrag wiederherstellen">';
  }


// --- Die Requests senden im Querytsring eine action 
//     und verwenden den HTTP-Body (Parameter postBody) zum Datentransport
function sendRequest( action, params, sync ) {  
  $("loading").show();  // - Visualisieren, dass eine Aktion an den Server ausgef�hrt wird
  new Ajax.Request( backendURL + "?action=" + action, params, sync ? true : false );
  }
  
// ---------------------------------------------------------------------------------------------
// Funktion wird im Moment nicht ben�tigt: setzt auf dem Client Neu -> Alt
// Die Daten brauchen demnach nicht vom Server neu angeliefert zu werden
function removeChangeIndicators() {
  $("buchungen").select("tr").each(function(row){
    row.removeClassName("new");
    if (row.hasClassName("deleted")) row.parentNode.removeChild(row);
    else 
      row.select("td").each(function(cell){
        cell.removeClassName("changed");
        });
    });
  }    
// ---------------------------------------------------------------------------------------------

  
  
document.observe( "dom:loaded", doOnLoad );  