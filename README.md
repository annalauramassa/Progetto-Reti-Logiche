# Progetto-Reti-Logiche
Repository per la Prova Finale di Reti Logiche AA 2020/2021 @Politecnico di Milano

Lo scopo del progetto è di implementare un componente hardware in VHDL che realizzi una [versione semplificata](https://github.com/annalauramassa/Progetto-Reti-Logiche/blob/main/Specifica%20Progetto%20AA%202020-2021.pdf) dell'algoritmo per [l'equalizzazione dell'istogramma di un'immagine](https://en.wikipedia.org/wiki/Histogram_equalization) in scala di grigio.

## Problema
Viene data in ingresso un'immagine di dimensione massima 128x128, salvata in memoria tramite il valore dei suoi pixel, da equalizzare.
L’equalizzazione dell’istogramma di un’immagine è un metodo usato per ricalibrare il contrasto dell’immagine stessa: i valori di intensità, quando troppo vicini, sono ridistribuiti su tutto l’intervallo di intensità e ciò comporta un aumento del contrasto.
L’algoritmo viene applicato solo a immagini in scala di grigio a 256 livelli.

## Implementazione
L'implementazione del componente è stata realizzata con una macchina a stati che calcola per ciascun pixel in ingresso il corrispondente valore equalizzato.
Il valore finale del pixel viene calcolato attraverso due cicli: nel primo la macchina legge tutti i pixel in ingresso per trovare il valore massimo e minimo, nel secondo calcola i valori equalizzati e li scrive in memoria.

## Testing
Il componente è stato testato mediante test privati forniti dal docente e numerosi test randomici; in particolare sono stati utilizzati test bench per verificare il reset asincrono, l'elaborazione di più immagini consecutivamente e il corretto funzionamento nel caso di immagini vuote, con dimensione massima (128x128 pixel) e con dimensione minima (1 pixel).

## Sviluppatori
* [Annalaura Massa](https://github.com/annalauramassa)
* [Eduardo Manfrellotti](https://github.com/EduardoManfrellotti)
