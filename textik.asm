;textovy editor TEXTIK!
;zdrojovy text

org 0x100

mov ah,0
mov al,0x2
int 0x10

call cls
mov al,radek_text_nahore
mov [radek],al
mov al,sloupek_text_vlevo
mov [sloupek],ah
call nastav_pozici_kurzoru
mov si,textove_pole
mov [pozice_v_textu],si
mov [pocatek_vypisu],si
call nastav_tvar_kurzoru
call vykresli_uvodni_obrazovku
call vypis_stranu
call vypis_jmeno_souboru
call vykresli_info_obrazovku

hlavni_smycka:
call vypis_jmeno_souboru
call vypis_stranu
call nacti_znak_bez_echa 
or al,al
jz near specialni_klavesa
cmp al,9
mov dx,tabulator
jz skoc
cmp al,ENTERcr
mov dx,zapis_ENTER
jz skoc
cmp al,BackSpace
mov dx,backspace
jz skoc
cmp al,15
mov dx,zadej_loadFile
jz skoc
cmp al,21
mov dx,zadej_saveFile
jz skoc
cmp al,14
mov dx,novy_soubor
jz skoc
mov dx,zapis_pismenko

skoc:			;zavola podprogram urceny v dx
call (dx)
jmp hlavni_smycka

specialni_klavesa:
call nacti_znak_bez_echa
cmp al,30
mov dx,vykresli_info_obrazovku
jz skoc
cmp al,83
mov dx,delete
jz skoc
cmp al,15
mov dx,zadej_loadFile
jz skoc
cmp al,81
mov dx,pagedown
jz skoc
cmp al,73
mov dx,pageup
jz skoc
cmp al,71
mov dx,_home
jz skoc
cmp al,79
mov dx,_end
jz skoc
cmp al,77
mov dx,kurzor_vpravo
jz skoc
cmp al,75
mov dx,kurzor_vlevo
jz skoc
cmp al,72
mov dx,kurzor_nahoru
jz skoc
cmp al,80
mov dx,kurzor_dolu
jz skoc
cmp al,9
mov dx,vykresli_info_obrazovku
jz skoc
cmp al,"t"
mov dx,dalsi_slovo
jz skoc
cmp al,"s"
mov dx,predchozi_slovo
jz skoc
cmp al,45
mov dx,ukonci_textik
jz skoc
jmp hlavni_smycka

zapis_pismenko:
push ax
call ldir_vpravo_pamet
pop ax
mov si,[pozice_v_textu]
mov [si],al
call kurzor_vpravo
ret

zapis_ENTER:
call ldir_vpravo_pamet
mov si,[pozice_v_textu]
mov byte [si],ENTERcr
inc si
mov [pozice_v_textu],si
push si
call ldir_vpravo_pamet
pop si
mov byte [si],0x0a
dec si
mov [pozice_v_textu],si
call kurzor_vpravo
ret

tabulator:
mov cx,rozmezi_tabulatoru
.smycka:
push cx
mov al,mezera
call zapis_pismenko
pop cx
loop .smycka
ret

ldir_vpravo_pamet:
mov cx,[delka_txt_pole]
mov di,textove_pole
add di,cx
inc cx
mov [delka_txt_pole],cx			;delku textoveho pole zvysime jiz tady, je to spolecny podprogram pro vloz pismeno i pro ENTER
mov si,di
inc di
mov cx,[delka_txt_pole]
add cx,textove_pole
sub cx,[pozice_v_textu]
.smycka					;= LDIR
mov al,[si]
mov [di],al
dec si
dec di
loop .smycka
ret

backspace:
call test_vlevo
cmp dl,zacTextu
jz .konec
mov si,[pozice_v_textu]
mov al,[si - 2]				;nachazime se zrovna pred ENTERem?
push ax
call ldir_vlevo_pamet
pop ax
mov si,[delka_txt_pole]
dec si
cmp al,ENTERcr
jnz .dalsi
dec si					;pokud jsme byli zrovna na ENTERu, je treba snizit citac 2x
.dalsi:
mov [delka_txt_pole],si
call kurzor_vlevo
.konec
ret

_home:
mov cx,pocet_sloupku
.smycka:
push cx
call kurzor_vlevo
call vyrovnej_kurzor
pop cx
mov si,[pozice_v_textu]
cmp byte [si],ENTERcr
jz .nalezeno
call test_vlevo
cmp dl,L_sloupek					;dosahl jsi leveho krajniho sloupku?
jz .konec
loop .smycka
.nalezeno:
call test_vlevo
cmp dl,zacTextu
jz .konec
call kurzor_vpravo
.konec:
ret

_end:
mov cx,pocet_sloupku
.smycka:
push cx
call kurzor_vpravo
call vyrovnej_kurzor
pop cx
mov si,[pozice_v_textu]
cmp byte [si],ENTERcr
jz .nalezeno
call test_vpravo
cmp dl,P_sloupek				;dosahl jsi praveho sloupku?
jz .nalezeno
loop .smycka
.nalezeno:
ret

dalsi_slovo:
mov cx,pocet_sloupku
.smycka:
push cx
call kurzor_vpravo
call vyrovnej_kurzor
pop cx
mov si,[pozice_v_textu]
cmp byte [si],mezera
jz .nalezeno
cmp byte [si],ENTERcr
jz .nalezeno
loop .smycka
.nalezeno:
call kurzor_vpravo
ret

predchozi_slovo:
mov cx,2				;musime najit 2x mezeru abychom se dostali na zacatek predchoziho slova
mov si,[pozice_v_textu]
cmp byte [si],mezera
jnz .smycka2
mov cx,1				;pokud zaciname mezerou, je predchozi slovo vlastne hned pred kurzorem a staci jen jedna hledaci smycka
.smycka2:
push cx
mov cx,pocet_sloupku
.smycka:
push cx
call kurzor_vlevo
call vyrovnej_kurzor
pop cx
mov si,[pozice_v_textu]
cmp byte [si],mezera
jz .nalezeno
cmp byte [si],ENTERcr
jz .nalezeno
loop .smycka
.nalezeno:
pop cx
loop .smycka2
call kurzor_vpravo
ret

delete:
call test_vpravo
cmp dl,konecTxt
jz .konec
mov si,[pozice_v_textu]
mov al,[si]				;je vpravo ENTER? => musime snizit delku_txt o 2!
push ax
call ldir_vlevo_delete
pop ax
mov si,[delka_txt_pole]
dec si
cmp al,ENTERcr
jnz .dalsi
dec si
.dalsi:
mov [delka_txt_pole],si
.konec:
ret

kurzor_vpravo:
call test_vpravo
cmp dl,konecTxt
jz .konec
cmp dh,D_radek
jnz .dalsi
call text_pozice_dolu
call inc_pozice_v_textu
call vyrovnej_kurzor
ret
.dalsi:
call inc_pozice_v_textu
call vyrovnej_kurzor
ret
.konec:
ret

kurzor_vlevo:
call test_vlevo
cmp dl,zacTextu
jz .koncime
cmp dh,H_radek
jnz .dalsi
call text_pozice_nahoru
call dec_pozice_v_textu
call vyrovnej_kurzor
ret
.dalsi:
call dec_pozice_v_textu
call vyrovnej_kurzor
ret
.koncime:
ret

kurzor_dolu:
mov cx,pocet_sloupku
.smycka
push cx
call kurzor_vpravo
pop cx
mov si,[pozice_v_textu]
cmp byte [si - 2],ENTERcr		;nasel jsi konec radku?
jz .radekNalezen
loop .smycka
ret
.radekNalezen:
ret

kurzor_nahoru:
mov al,[radek]					;pokud jsme uplne nahore
cmp al,radek_text_nahore			;nastav kurzor nahoru do leveho rohu
jnz .dalsi						;abychom prinutili kurzor_nahoru scrollovat
mov si,[pocatek_vypisu]
mov [pozice_v_textu],si
mov al,sloupek_text_vlevo
mov [sloupek],al
.dalsi:
mov cx,pocet_sloupku
.smycka:
push cx
call kurzor_vlevo
pop cx
mov si,[pozice_v_textu]
cmp byte [si],ENTERcr
jz .nalezeno
loop .smycka
cmp cx,0					;neni-li na radku zadny ENTER, jiz nic neposunuj.
jz .konec
.nalezeno:
mov cx,pocet_sloupku		;jsme na konci predchoziho radku, ted musime najit jeho zacatek
.smycka2:
push cx
call kurzor_vlevo
pop cx
mov si,[pozice_v_textu]
cmp byte [si],ENTERcr
jz .nalezeno2
call test_vlevo
cmp dl,L_sloupek			;dosahli jsme na predchozim radku leveho sloupce?
jz .konec					;ano - jsme jiz tam, kde potrebujeme
loop .smycka2
.nalezeno2:
call test_vlevo
cmp dl,zacTextu
jnz .neposunuj				;jsme-li na uplnem zacatku textu, je uz kurzor spravne nastaven na zacatku radku, neni pred nim zadny ENTER
ret
.neposunuj:
call kurzor_vpravo
.konec:
ret

pagedown:
mov cx,radkuProVYPISstrany
.smycka:
push cx
call kurzor_dolu
pop cx
loop .smycka
call test_vpravo
cmp dl,konecTxt					;jsi-li na konci textu, nech pocatek vypisu tam, kde je
jz .konec
mov si,[pozice_v_textu]
mov [pocatek_vypisu],si				;aby se PgDn vypisovala od shora... a ne vespod
.konec:
ret

pageup:
mov cx,radkuProVYPISstrany
.smycka
push cx
call kurzor_nahoru
pop cx
loop .smycka
ret

novy_soubor:
call nakresli_ramecek
mov al,souradniceY + 4
mov ah,souradniceX + 9
mov [radek],al 
mov [sloupek],ah
call nastav_pozici_kurzoru
mov ah,0x09
mov dx,ano_ne_novy_text
int 0x21
call nacti_znak
cmp al,"a"
jz .dale
ret
.dale:
call novy_soubor2
mov al,radek_text_nahore
mov [radek],al
mov al,sloupek_text_vlevo
mov [sloupek],ah
call nastav_pozici_kurzoru
mov si,textove_pole
mov [pozice_v_textu],si
mov [pocatek_vypisu],si
mov cx,1
mov [delka_txt_pole],cx
call cls
call vykresli_uvodni_obrazovku
call vypis_stranu
ret
novy_soubor2:
mov si,textove_pole
mov cx,max_velikost_souboru + 1
.smycka
mov byte [si],mezera
inc si
loop .smycka
ret

zadej_loadFile:
call nakresli_ramecek
mov al,souradniceY + 4
mov ah,souradniceX + 5
mov [radek],al 
mov [sloupek],ah
call nastav_pozici_kurzoru
mov ah,0x09
mov dx,ano_ne_load_text
int 0x21
call nacti_znak
cmp al,"a"
jz .dale
ret
.dale:
call novy_soubor2
mov al,souradniceY + 5
mov [radek],al
mov ah,souradniceX + 5
mov [sloupek],ah
call nastav_pozici_kurzoru
mov dx,retezecLoad
mov ah,0x09
int 0x21
mov ah,0x0a
mov dx,prikazovy_radek_buffer
int 0x21
mov si,prikazovy_radek_buffer
mov cx, 15
.smycka:
inc si
cmp byte [si],ENTERcr		;nahrad ENTER nulou pro loadfile
loopnz .smycka
mov byte [si],0
jc near ukonci_textik			;pri chybe ukonci Textik
mov ah,0x3d
mov dx,prikazovy_radek_buffer + 2 ;preskocime uvozovaci znaky DOSovskeho cteni radku
mov al,0
int 0x21
mov bx,ax
mov ah,0x3f
mov dx,textove_pole
mov cx,max_velikost_souboru
int 0x21
jc near ukonci_textik
inc ax
mov [delka_txt_pole],ax		;zapiseme skutecnou delku precteneho souboru do textoveho pole zvetsenou o jedna (aby se kurzor vzdy dostalza posledni znak)
mov ah,0x3e
int 0x21
call cls
call vykresli_uvodni_obrazovku
mov al,radek_text_nahore
mov [radek],al
mov al,sloupek_text_vlevo
mov [sloupek],ah
call nastav_pozici_kurzoru
mov si,textove_pole
mov [pozice_v_textu],si
mov [pocatek_vypisu],si
ret

retezecLoad	db "File name: $"
retezecSave	db "Save as: $"


prikazovy_radek_buffer	db 15,0
jmeno_souboru			db 'noname.txt'
					db 0
					times 15 db 0

vypis_jmeno_souboru:
mov al,radek_text_nahore - 2
mov ah,sloupek_text_vlevo + pocet_sloupku - 10
mov [radek],al
mov [sloupek],ah
call nastav_pozici_kurzoru
mov cx,pocet_sloupku
mov si,jmeno_souboru
.smycka:
mov dl,[si]
cmp byte [si],0
jz .konec
push dx
push cx
mov ah,0x09
mov al,dl
mov bh,0
mov bl,barva_okenek		;barva textu a pozadi
mov cx,1
int 0x10
pop cx
pop dx
call tiskni_1znak
inc si
loop .smycka
.konec:
ret

zadej_saveFile:
call nakresli_ramecek
mov al,souradniceY + 4
mov [radek],al
mov ah,souradniceX + 5
mov [sloupek],ah
call nastav_pozici_kurzoru
mov dx,retezecSave
mov ah,0x09
int 0x21
mov ah,0x0a
mov dx,prikazovy_radek_buffer
int 0x21
mov dx,retezecSave
mov ah,0x09
int 0x21
mov si,prikazovy_radek_buffer
mov cx, 15
.smycka:
inc si
cmp byte [si],ENTERcr		;nahrad ENTER nulou pro loadfile
loopnz .smycka
mov byte [si],0
jc near ukonci_textik			;pri chybe ukonci Textik

mov ah,0x6c				;inteligentni otevreni souboru, i pokud neexistuje, vytvori novy soubor
mov al,0
mov bx,1					;pouze zapis
mov cx,0x20				;atributy budou normalni
mov dx,0x012				;prepis soubor nebo ho vytvor
mov si,prikazovy_radek_buffer + 2 ;jmeno souboru
int 0x21

mov bx,ax
mov ah,0x40
mov dx,textove_pole
mov cx,[delka_txt_pole]
dec cx					;snizime delku souboru o 1, protoze pri load a novem souboru je o 1 vetsi
int 0x21					;sejvni soubor

jc near ukonci_textik
inc ax
mov [delka_txt_pole],ax		;zapiseme skutecnou delku precteneho souboru do textoveho pole zvetsenou o 1
mov ah,0x3e
int 0x21
call cls
call vykresli_uvodni_obrazovku
ret

ldir_vlevo_pamet:
mov di,[pozice_v_textu]
mov si,di
dec si
mov al,[si]
cmp al,0x0a
jnz .NoEnter
mov [pozice_v_textu],si		;zapiseme si, aby se pak spravne nastavil kurzor
dec si					;pozice ukazuje na 0x0a, kurzorem vlevo se pak vse srovna
.NoEnter
mov cx,[delka_txt_pole]
add cx,textove_pole
sub cx,[pozice_v_textu]
inc cx
.smycka					;= LDIR
mov al,[di]
mov [si],al
inc si
inc di
loop .smycka
ret

ldir_vlevo_delete:
mov di,[pozice_v_textu]
mov si,di
inc di
mov al,[di]
cmp al,0x0a
jnz .NoEnter
inc di					;pokud jsme na ENTERu, musime odmazat i 0x0a
.NoEnter:
mov cx,[delka_txt_pole]
add cx,textove_pole
sub cx,[pozice_v_textu]
.smycka					;= LDIR
mov al,[di]
mov [si],al
inc si
inc di
loop .smycka
ret

test_vlevo:
mov si,[pozice_v_textu]		;otestuj uplny zacatek textu
cmp si, textove_pole
jz .zacatekTextu
mov al,[sloupek]			;otestuj levy sloupek vypisu
cmp al,sloupek_text_vlevo
jz .levySloupek
mov dx,vPoradku			;je-li vse v poradku, vrat se
ret
.zacatekTextu:
mov dx,zacTextu
ret
.levySloupek:
mov dx,L_sloupek
mov al,[radek]
cmp al,radek_text_nahore
jz .radekNahore
ret
.radekNahore:
mov dh,H_radek
ret
vPoradku	equ 0
zacTextu	equ 1			;navratove kody testu
L_sloupek	equ 2
H_radek	equ 3

konec_textu?:
push si
push di
mov si,textove_pole			;jsi na konci textu?
mov di,[delka_txt_pole]
add di,si
mov si,[pozice_v_textu]
inc si					;testuje se az pozice za uplne poslednim znakem. Jinak by nefungovalo vkladani do uplne prazdneho souboru.
cmp si,di
pop di
pop si
ret

test_vpravo:
mov si,[pozice_v_textu]
call konec_textu?
jz .konecTextu
cmp byte [si],ENTERcr		;jsi na znaku ENTER?
jz .enter
mov al,[sloupek]			;jsi na obrazovce na kraji vpravo?
cmp al,pocet_sloupku
jz .sloupekVpravo
mov dx,vPoradku			;vse je ok
ret
.konecTextu:
mov dx,konecTxt
ret
.enter				
mov dx,enterPos			;je to posledni radek?
mov al,[radek]
cmp al,radkuProVYPISstrany + 1
jz .dolniRadek
ret
.sloupekVpravo:
mov dx,P_sloupek			;je to posledni radek?
mov al,[radek]
cmp al,radkuProVYPISstrany + 1
jz .dolniRadek
ret
.dolniRadek
mov dh,D_radek
ret
konecTxt	equ 1
P_sloupek	equ 2
enterPos	equ 3
D_radek	equ 4

text_pozice_nahoru:
call test_vlevo
cmp dl,zacTextu
jz .konec				;jsi-li na zacatku textu, neni kam scrollovat
cmp dl,L_sloupek			;zmenu proved jen je-li kurzor na kraji radku!
jnz .konec
cmp dh,H_radek		;jsme opravdu na hornim radku?
jnz .konec
mov si,[pocatek_vypisu]
dec si
cmp byte [si],0x0a		;je tam ukoncovaci znak Enteru?
jnz .bezEnteru			;neni - skoc
dec si				;uprav na posledni znak predchoz radku
cmp si,textove_pole		;nejsme nahodou na uplnem zacatku textu? nezacina text prave ENTEREm?
jnz .dalsi				;ano, ENTER je prvni znak textu, pred nim jiz zadny text neni, nic tedy neposunuj
mov [pocatek_vypisu],si
ret
.dalsi:
dec si				;jsme na poslednim znaku
.bezEnteru:
mov cx,pocet_sloupku - 1
.smycka:
cmp byte [si],ENTERcr	;uz mas adresu konce predchoziho radku?
jz .radekNalezen		;ano, mame ji
cmp si,textove_pole
jz .radekNalezenBezINC
dec si
loop .smycka
dec si				;radek je dlouhy, neni v nem ENTER, nezvysuj SI
dec si
.radekNalezen
inc si				;presun se na prvni znak
inc si
.radekNalezenBezINC
mov [pocatek_vypisu],si
.konec
ret
.druhyEnter:
mov [pocatek_vypisu],si
ret

text_pozice_dolu:
call test_vpravo
cmp dl,konecTxt			;jsme na konci textu?
jz .konec
cmp dh,D_radek
jnz .konec
mov cx,pocet_sloupku
mov si,[pocatek_vypisu]
cmp byte [si],ENTERcr		;zacina vypisujici pozice ENTERem?  ano - zvys ji o 2 a skoci
jz .nalezeno
.smycka:
inc si
cmp byte [si],ENTERcr
jz .nalezeno
loop .smycka
mov [pocatek_vypisu],si		;radek je dlouhy, bez ENTERu
ret
.nalezeno:
inc si					;preskocime na prvni znak dalsiho radku
inc si
mov [pocatek_vypisu],si
ret
.konec:
ret

inc_pozice_v_textu:
call konec_textu?
jz .jsiNaKonciTextu
mov si,[pozice_v_textu]
cmp byte [si],ENTERcr				;jsme-li na ENTEru, musime SI
jz .enter							;zvysit 2x
inc si
mov [pozice_v_textu],si
;inc byte [sloupek]
.jsiNaKonciTextu:
ret
.enter:
inc si
inc si
mov [pozice_v_textu],si
ret

dec_pozice_v_textu:
mov si,[pozice_v_textu]
cmp si,textove_pole					;jsi na konci textu?
jz .jsiNaZacatkuTextu
cmp byte [si - 2],ENTERcr				;jsme na zacatku radku pred Enterem?
jnz .dalsi
dec si
dec si
mov [pozice_v_textu],si
ret
.dalsi:
dec si
mov [pozice_v_textu],si
ret
.jsiNaZacatkuTextu:
ret

vyrovnej_kurzor:
mov al,1
mov [tiskni_var],al
call vypis_stranu
xor al,al
mov [tiskni_var],al
ret

vypis_stranu:
call zmizni_kurzor						;kurzor nema byt videt
mov byte [radek],radek_text_nahore			;inicializace mista na obrazovce
mov byte [sloupek],sloupek_text_vlevo		;nastavime kurzor do horniho leveho rohu
call nastav_pozici_kurzoru
mov si,[pocatek_vypisu]					;inicializace mista v pameti, odkud vypisujeme
mov cx,radkuProVYPISstrany				;pocet radku vypisu mensi nez je celkova obrazovka (neprekryjeme ramecek kolem textu)
vypis_stranu_radky:
push cx								;schovame na pozdeji
mov cx,pocet_sloupku					;pocet sloupku vypisu

vypis_stranu_sloupky:
call tiskni_pismenoZeStrany
loop vypis_stranu_sloupky
cmp byte [si],13						;zkontroluj, jestli je v textu ENTER, ano = je treba zvetsit pozici v pameti
jnz odradkuj							;aby podprogram vypisoval i nasledujici znaky
inc si								; 0d, 0a - ENTER
inc si
odradkuj:
mov ah,[radek]
inc ah
mov  [radek],ah
mov al,sloupek_text_vlevo
mov [sloupek],al
call nastav_pozici_kurzoru
pop cx								;obnov pocet radku
loop vypis_stranu_radky
mov al,[rd_schov]						;nastav kurzor tam, kde ma byt
mov [radek],al
mov al,[sl_schov]
mov [sloupek],al
call nastav_pozici_kurzoru
call nastav_tvar_kurzoru
ret
rd_schov	db radek_text_nahore
sl_schov	db sloupek_text_vlevo

tiskni_pismenoZeStrany:
mov dl,[si]
cmp dl,13							;jsi u ENTERu?
jz tiskni_ENTER
push si
mov si,textove_pole					;jsi na poslednim znaku, tedy konci textu?
mov di,[delka_txt_pole]
add di,si
pop si
cmp si,di
jz tiskni_konecRadky
cmp si,[pozice_v_textu]				;jsme-li presne na pozici ukazatele
jnz .dokonci						;do textu, nastav tam i kurzor
mov al,[radek]						;schovej radek a sloupek
mov [rd_schov],al					;pro pozdejsi presne nastaveni
mov al,[sloupek]					;kurzoru
mov [sl_schov],al
.dokonci:
mov al,[tiskni_var]
or al,al
jnz .nebarvi
push cx
push ax
push bx
push dx
mov ah,0x09
mov al,dl
mov bh,0
mov bl,barva_editoru		;barva textu a pozadi
mov cx,1
int 0x10
pop dx
pop bx
pop ax
pop cx
.nebarvi:
call tiskni_1znak
inc si
inc byte [sloupek]
ret
tiskni_ENTER:
cmp si,[pozice_v_textu]				;jsme-li presne na pozici ukazatele
jnz tiskni_konecRadky				;nastav tam i kurzor
mov al,[radek]						;schovej radek a sloupek
mov [rd_schov],al					;pro pozdejsi presne nastaveni
mov al,[sloupek]					;kurzoru
mov [sl_schov],al
tiskni_konecRadky:
mov al,[tiskni_var]
or al,al
jnz .nebarvi
mov dl,' '								;dopln radek mezerami, kdyz je
push cx
push ax
push bx
push dx
mov ah,0x09
mov al,dl
mov bh,0
mov bl,barva_editoru	;barva textu a pozadi
mov cx,1
int 0x10
pop dx
pop bx
pop ax
pop cx
.nebarvi:
call tiskni_1znak						;radek ukoncen ENTEREM
ret

napis_nadpis
mov ah,0x09
mov dx,nadpis
int 0x21
ret
nadpis 	db "TEXTIK! - the text editor - revised 29/12/08 $"

prikazovy_radek_cls:
call prikaz_radek_pozice
mov cx,pocet_sloupku
.smycka:
mov dl," "
call tiskni_1znak
loop .smycka
call prikaz_radek_pozice
ret

prikaz_radek_pozice:
mov al,pocet_radku + 1
mov ah,sloupek_text_vlevo - 1
mov [radek],al
mov [sloupek],ah
call nastav_pozici_kurzoru
ret

napis_instrukce
mov al,pocet_radku + 1
mov ah,sloupek_text_vlevo - 1
mov [radek],al 
mov [sloupek],ah
call nastav_pozici_kurzoru
mov ah,0x09
mov dx,instrukce_text
int 0x21
ret
instrukce_text	db "ALT+X quit, CTRL+O open, CTRL+U save, CTRL+N new, ALT+A about $"

nastav_pozici_kurzoru_promenne:
mov byte [radek],ch
mov byte [sloupek],cl
nastav_pozici_kurzoru:
mov ah,[tiskni_var]
or ah,ah
jnz .konec
mov ah,0x02
mov bh,0
mov dh,[radek]
mov dl,[sloupek]
int 0x10
.konec:
ret

vykresli_uvodni_obrazovku:
mov byte [sloupek],0
mov byte [radek],0
call nastav_pozici_kurzoru
call napis_nadpis
mov byte [sloupek],0
mov byte [radek],1
call nastav_pozici_kurzoru
call kresli_ramecek_radku
mov byte [sloupek],0
call kresli_ramecek_sloupek
mov byte [sloupek],pocet_sloupku + 1
call kresli_ramecek_sloupek
mov byte [sloupek],0
mov byte [radek],pocet_radku + 1
call nastav_pozici_kurzoru
call napis_instrukce
ret

kresli_ramecek_radku:
mov dl,201
call tiskni_1znak
mov al,pocet_sloupku
mov dl,205
call ramecek_radka2
mov dl,187
call tiskni_1znak
mov al,pocet_radku	
mov [radek],al
call nastav_pozici_kurzoru
mov dl,200
call tiskni_1znak
mov al,pocet_sloupku
call ramecek_radka2
mov dl,188
call tiskni_1znak
ret

ramecek_radka2:
mov al,pocet_sloupku
mov dl,205
ramecek_radka3:
push ax
call tiskni_1znak
pop ax
dec al
cmp al,0
jnz ramecek_radka3
ret

kresli_ramecek_sloupek:
mov cx,radkuProVYPISstrany
mov byte [radek],2
.smycka:
call nastav_pozici_kurzoru
mov dl,186
call tiskni_1znak
mov al,[radek]
inc al
mov [radek],al
loop .smycka
ret

cls:
mov cx,textovy_rozsah_VRAM
mov byte [sloupek],0
mov byte [radek],0
call nastav_pozici_kurzoru
.smycka
push cx
push ax
push bx
push dx
mov ah,0x09
mov al,186
mov bh,0
mov bl,barva_popisku
mov cx,1
int 0x10
pop dx
pop bx
pop ax
pop cx
mov dl,' '
call tiskni_1znak
loop .smycka
mov byte [sloupek],0
mov byte [radek],0
call nastav_pozici_kurzoru
ret

nacti_znak
mov ah,0x1
int 0x21
ret

nacti_znak_bez_echa
mov ah,0x08
int 0x21
cmp al,ENTERcr
jz .konec
cmp al,ESCcr
jz .konec
cmp al,BackSpace
jz .konec
.konec:
ret

nastav_tvar_kurzoru
mov  ah,0x1
mov ch,00000001b			;tvar kurzoru
mov cl,8					;vyska kurzoru
int 0x10
ret 

zmizni_kurzor
mov ah,0x1
mov ch,00100001b 			;kurzor je neviditelny
mov cl,8					;vyska kurzoru
int 0x10					;tvar kurzoru nejak moc nefunguje
ret

tiskni_1znak:
cmp dl,9					;odstran tabulatory
jnz .dalsi
cmp dl,ENTERcr			;o radkovani se stara jina cast programu, nemichej ji sem
jz .konec
mov dl,' '
.dalsi:
mov ah,0x02
mov al,[tiskni_var]
or al,al
jnz .konec
int 0x21
.konec:
ret
tiskni_var db 0

vykresli_info_obrazovku:
call nakresli_ramecek
call napis_info_texty
call nacti_znak
call vykresli_uvodni_obrazovku
ret

nakresli_ramecek:
mov al,souradniceX + 1
mov ah,souradniceY + 1
mov cx,pocetRd - 1
.smycka2:
mov [sloupek],al
mov [radek],ah
push cx
push ax
call nastav_pozici_kurzoru
mov cx,pocetSl 
mov dl," "
.smycka:
call tiskni_info_znak
loop .smycka
pop ax
pop cx
inc ah
loop .smycka2
mov byte [sloupek],souradniceX
mov byte [radek],souradniceY
call nastav_pozici_kurzoru
call kresli_info_radku
mov byte [sloupek],souradniceX
call kresli_info_sloupek
mov byte [sloupek],souradniceX + pocetSl + 1
call kresli_info_sloupek
ret

napis_info_texty:
mov al,souradniceY + 3
mov ah,souradniceX + 3
mov [radek],al 
mov [sloupek],ah
call nastav_pozici_kurzoru
mov ah,0x09
mov dx,info_text
int 0x21
mov al,souradniceY + 4
mov ah,souradniceX + 3
mov [radek],al 
mov [sloupek],ah
call nastav_pozici_kurzoru
mov ah,0x09
mov dx,info_text2
int 0x21
mov al,souradniceY + 6
mov ah,souradniceX + 3
mov [radek],al 
mov [sloupek],ah
call nastav_pozici_kurzoru
mov ah,0x09
mov dx,info_text3
int 0x21
ret

kresli_info_radku:
mov dl,201
call tiskni_info_znak
mov al,pocetSl
mov dl,205
call info_radka2
mov dl,187
call tiskni_info_znak
mov al,souradniceY + pocetRd - 1
mov [radek],al
call nastav_pozici_kurzoru
mov dl,200
call tiskni_info_znak
mov al,pocetSl
call info_radka2
mov dl,188
call tiskni_info_znak
ret

info_radka2:
mov al,pocetSl
mov dl,205
.ramecek_radka3:
push ax
call tiskni_info_znak
pop ax
dec al
cmp al,0
jnz .ramecek_radka3
ret

kresli_info_sloupek:
mov cx,pocetRd - 2
mov byte [radek],souradniceY + 1
.smycka:
call nastav_pozici_kurzoru
mov dl,186
call tiskni_info_znak
mov al,[radek]
inc al
mov [radek],al
loop .smycka
ret

tiskni_info_znak:
push cx
push dx
mov ah,0x09
mov al,dl
mov bh,0
mov bl,barva_okenek				;barva textu a pozadi
mov cx,1
int 0x10
pop dx
pop cx
call tiskni_1znak
ret

souradniceX	equ 19
souradniceY	equ 7
pocetSl		equ 40
pocetRd		equ 10

info_text		db "TEXTIK! - the text editor$"
info_text2		db "an exercise in x86 asm, August 2006$"
info_text3		db "press a key...$"
ano_ne_text	db "Quit the program?  a/n: $"
ano_ne_novy_text	db "New file?  a/n: $"
ano_ne_load_text	db "Open file?  a/n: $"


ukonci_textik
call nakresli_ramecek
mov al,souradniceY + 4
mov ah,souradniceX + 9
mov [radek],al 
mov [sloupek],ah
call nastav_pozici_kurzoru
mov ah,0x09
mov dx,ano_ne_text
int 0x21
call nacti_znak
cmp al,"a"
jz .ukoncit
ret
.ukoncit:
call cls
call zaverecny_text
mov ah,00
int 0x21
ret

zaverecny_text
mov ah,0x09
mov dx,zaver_txt
int 0x21
ret
zaver_txt	db 0xd,0xa,"TEXTIK!  - exercise in x86 assembler, August 2006, Kapoun software"
		db 0xd,0xa, "Compiled in NASM"
		db 0xd,0xa, '$'

barva_editoru			equ 30
barva_okenek			equ 78
barva_popisku			equ 15
ENTERcr				equ 13
ESCcr				equ 27
mezera				equ 32
BackSpace			equ 8
rozmezi_tabulatoru		equ 5
textovy_rozsah_VRAM		equ   80*25;			;80*50
pocet_radku			equ 23 ;48 ;22		;max pocet radku
radkuProVYPISstrany		equ pocet_radku - 2
radek_text_nahore		equ 2		;kde se nahore zacina vypis?
sloupek_text_vlevo		equ 1		;kde vlevo zacneme vypis?
pocet_sloupku			equ 80 - sloupek_text_vlevo  - 1 ;max pocet sloupku vypisu
radek 				db 0
sloupek 				db 0
max_velikost_souboru		equ 35000
pozice_v_textu			dw textove_pole
pocatek_vypisu 			dw textove_pole
delka_txt_pole			dw textove_pole_konec - textove_pole + 1 ;velikost musi byt aspon 1 byte, kvuli prvnimu vkladanemu znaku do prazdneho souboru

textove_pole 			


textove_pole_konec
					times max_velikost_souboru db mezera

