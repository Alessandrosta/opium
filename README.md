# OPIUM POPULORUM

### Game Design & Technical Reference (v0.1)

## 1. Descrizione generale

**Opium Populorum** è un gioco strategico competitivo da 2 a 10 giocatori, ambientato nel Mediterraneo del I millennio d.C., in cui ogni giocatore guida una religione storica minore con l’obiettivo di imporsi come culto dominante prima dell’affermazione del Cristianesimo.

Il gioco combina:

* gestione risorse (PA, fedeli, teologia, sesterzi, favore imperiale),
* controllo territoriale indiretto (templi e città),
* card-driven gameplay (carte vantaggio/svantaggio/rapide/continue),
* progressione temporale a ere,
* interazione diretta e indiretta tra giocatori.

La presente versione è pensata per supportare:

* una **conversione digitale** (client/server o peer-to-peer),
* una **modalità online asincrona o sincrona**,
* future **espansioni modulari**.

---

## 2. Condizioni di vittoria

Un giocatore vince immediatamente se, in qualunque momento del proprio turno, soddisfa **tutte** le seguenti condizioni:

* **Fedeli ≥ 90**
* **Teologia ≥ 40**
* **Templi costruiti ≥ 7**

### Vittoria a fine partita

Se al termine dell’anno **476 d.C.** nessun giocatore ha vinto:

Punteggio totale:

* Fedeli → 1 punto ciascuno
* Teologia → 2 punti ciascuno
* Templi → 10 punti ciascuno

In caso di pareggio:

1. più templi
2. più punti teologia

---

## 3. Giocatori, religioni e setup iniziale

### Religioni disponibili (max 10)

| Religione                 | Capitale iniziale | Colore    |
| ------------------------- | ----------------- | --------- |
| Culto di Mitra            | Antiochia         | Rosso     |
| Culto di Iside e Serapide | Alexandria        | Marrone   |
| Culto di Cibele           | Ephesus           | Nero      |
| Religione fenicio-punica  | Carthago          | Arancione |
| Religione celtica         | Massilia          | Verde     |
| Culto di Sabazio          | Athenae           | Bianco    |
| Religione iberica         | Corduba           | Rosa      |
| Culto di Helios           | Syracusae         | Giallo    |
| Religione etrusca         | Volaterrae        | Viola     |
| Manicheismo               | Hierosolyma       | Blu       |

Ogni giocatore riceve:

* 1 plancia religione
* 1 pedina giocatore
* segnalini per Fedeli, Teologia, Favor Imperiale
* **mano iniziale di 5 carte**
* **0 sesterzi**
* **100 punti favore imperiale**

---

## 4. Struttura temporale (linea del tempo)

La partita è divisa in **3 ere**, ciascuna con un proprio mazzo carte.

| Era | Periodo      | PA per turno |
| --- | ------------ | ------------ |
| I   | 1–150 d.C.   | 4            |
| II  | 175–300 d.C. | 5            |
| III | 325–476 d.C. | 6            |

Ogni turno rappresenta **25 anni**, eccetto l’ultimo (475–476).

### Anni degli imprevisti

* 125 d.C.
* 275 d.C.
* 450 d.C.

Durante questi turni:

* nessun movimento
* nessuna costruzione
* nessuna pesca carte normali
* ogni giocatore pesca **1 carta imprevisto** dell’era

---

## 5. Turno di gioco (loop principale)

Ogni turno segue questa sequenza:

### 5.1 Entrate automatiche

* PA secondo era (reset ogni turno, non accumulabili)
* +3 fedeli
* +1 fedele per ogni tempio costruito
* Sesterzi:

  * +7000 all’inizio di ogni era
  * +1000 per ogni nuovo scaglione di 10 fedeli raggiunto

### 5.2 Pesca carte

* Pesca 2 carte dal mazzo era
* Scegline 1 da tenere in mano
* L’altra va nel **mazzo scarti coperti**
* Le carte non sono obbligatorie da usare nello stesso turno

### 5.3 Azioni disponibili (uso PA)

* Movimento: 2 PA per città adiacente
* Costruzione tempio: 3 PA + 3000 sesterzi
* Attivazione carte (secondo costo indicato)
* Scartare 1 carta dalla mano → +1 PA (una sola volta per turno)

Le carte rapide possono essere giocate anche **fuori turno**.

---

## 6. Movimento e città

### Tipologie di città

* **Città normali** (puntino nero)
* **Capitali** (una per religione)

### Effetti visita (una tantum per città)

* Città normale: +3 fedeli
* Capitale avversaria: +5 teologia

Visitare una città **sblocca permanentemente** la possibilità di costruirvi un tempio.

---

## 7. Templi

* Max **1 tempio per religione per città**
* Slot per città:

  * 2 slot standard
  * 1 slot se giocatori < 5
* Ogni tempio:

  * +1 fedele per turno
  * −5 favore imperiale

### Requisiti costruzione

* 3 PA
* 3000 sesterzi
* Limite dinamico:

  * 1 tempio ogni **10 fedeli posseduti + 1**
  * es: 16 fedeli → max 2 templi

---

## 8. Carte

### Tipologie

* **Vantaggio**
* **Svantaggio**
* **Rapide**
* **Continue**
* **Carte città**
* **Imprevisti**

Ogni carta specifica:

* costo in PA
* tipo
* effetto
* era (I, II, III)

### Carte continue

* rimangono attive sotto la plancia
* alcune hanno costo PA aumentato (ampolla, scambio anime, baratto divino)
* effetti moltiplicativi sostituiti con bonus fissi (+2)

### Carte città

* mazzo separato
* attivate a fine giro
* effetti globali dipendenti dalle città visitate
* capitali → carte continue inserite nei mazzi era

---

## 9. Mercato: foro e asta

### Foro (carta rapida)

* ogni giocatore espone minimo 2 carte dalla mano
* carte acquistabili con sesterzi o scambiabili

### Asta

* si rivelano 3 carte dal mazzo
* vendute solo in cambio di sesterzi

---

## 10. Sesterzi

Uso principale:

* costruzione templi
* aste
* mercato
* conversione in favore imperiale

Conversione:

* 1000 sesterzi → +1 favore

Fine era:

* tutte le carte in mano scartate
* +1000 sesterzi per carta scartata

---

## 11. Favore imperiale

Valore iniziale: **100**

Riduzioni:

* −5 per ogni tempio
* −1 per ogni nuova città visitata

### Scaglioni

| Scaglione     | Favore | Effetto                                         |
| ------------- | ------ | ----------------------------------------------- |
| Tranquillitas | 100–76 | nessuno                                         |
| Cave!         | 75–51  | dadi: −3 fedeli                                 |
| Persecutio    | 50–26  | dadi: −5 fedeli, −1 teologia                    |
| Mo socazzi    | 25–1   | come sopra, scegli 3 numeri                     |
| 0             | —      | eliminazione (templi distrutti, carte all’asta) |

Sistema dadi: scelta numeri + lancio 2 dadi (metodo da rifinire in testing).

---

## 12. Versione Light

* Turni da 50 anni
* PA raddoppiati
* Costi ed effetti carte raddoppiati
* Templi e imprevisti invariati
* Timeline:
  1 – 50 – 100 – 150 – 200 – 250 – 300 – 350 – 400 – 450 – 476

---

## 13. Considerazioni per implementazione digitale

Elementi chiave da modellare:

* stato persistente dei giocatori (fedeli, teologia, favori, templi)
* grafo delle città
* gestione asincrona delle carte rapide
* tracciamento città visitate
* motore eventi (imprevisti, carte città, fine era)
* sistema aste/mercato sincrono

---

## 14. Stato del progetto

* Regolamento: **stabile ma non definitivo**
* Bilanciamento: **da testare**
* Espansioni: **non incluse**
* Meccaniche rimosse: controllo regioni, Roma separata, città caratterizzate

---

Se vuoi, **nel prossimo passo** posso:

* trasformare questo README in **specifica tecnica per sviluppatori**
* definire **modello dati (entità / relazioni / stati)**
* oppure iniziare direttamente con **pseudocodice del game loop**.
