(***********************************************)
(*                                             *)
(* Tetris (GUI Demo Game)                      *)
(* Copyright (c) 1999 by TMT Development Corp. *)
(* Author: Vadim Bodrov, TMT Development Corp. *)
(*                                             *)
(* Targets:                                    *)
(*   WIN32 GUI application                     *)
(*                                             *)
(* VBXE Atari version by Tebe/Madteam          *)
(*                                             *)
(***********************************************)

program Tetris;

{$r tetris_vbxe.rc}

uses crt, atari, sysutils, graph, vbxe, joystick;

type

 hBitMap = array [0..255] of byte;
 hBrush = array [0..7] of byte;

const

  vram = $010000;
  bmp = $030000;
  
  blocks = bmp + 320*240;

var
  vbxe_ram: TVBXEMemoryStream;

  blt: TBCB absolute VBXE_BCBADR+VBXE_WINDOW;

  GridN, GridS: array [0..19, 0..9] of Byte;

  MS, Score: cardinal;

  Xp, Yp: Word;
  
  OldX, OldY, X, Y: shortint;
  
  i, Ok, StoreLines, Level: Byte;
  Figure, FigureA, FigureB, OldNo: Byte;
  Lines, SlideNo: byte;

  DelayVal: Byte;

//  UseSound, UseMusic: Boolean;

  Paused, ColoredFigures, AutoLevel: Boolean;

  hlp: cardinal;


const
Tetromino: array [0..27, 0..7] of shortint =
  (( 0,  0,  1,  0,  0,  1,  1,  1),
   ( 0,  0,  1,  0,  0,  1,  1,  1),
   ( 0,  0,  1,  0,  0,  1,  1,  1),
   ( 0,  0,  1,  0,  0,  1,  1,  1),
   (-2,  0, -1,  0,  0,  0,  1,  0),
   ( 0, -1,  0,  0,  0,  1,  0,  2),
   (-2,  0, -1,  0,  0,  0,  1,  0),
   ( 0, -1,  0,  0,  0,  1,  0,  2),
   (-1,  0,  0,  0,  0,  1,  1,  1),
   ( 1, -1,  0,  0,  1,  0,  0,  1),
   (-1,  0,  0,  0,  0,  1,  1,  1),
   ( 1, -1,  0,  0,  1,  0,  0,  1),
   ( 0,  0,  1,  0, -1,  1,  0,  1),
   ( 0, -1,  0,  0,  1,  0,  1,  1),
   ( 0,  0,  1,  0, -1,  1,  0,  1),
   ( 0, -1,  0,  0,  1,  0,  1,  1),
   ( 0, -1, -1,  0,  0,  0,  1,  0),
   ( 0, -1, -1,  0,  0,  0,  0,  1),
   (-1,  0,  0,  0,  1,  0,  0,  1),
   ( 0, -1,  0,  0,  1,  0,  0,  1),
   ( 1, -1, -1,  0,  0,  0,  1,  0),
   (-1, -1,  0, -1,  0,  0,  0,  1),
   (-1,  0,  0,  0,  1,  0, -1,  1),
   ( 0, -1,  0,  0,  0,  1,  1,  1),
   (-1, -1, -1,  0,  0,  0,  1,  0),
   ( 0, -1,  0,  0, -1,  1,  0,  1),
   (-1,  0,  0,  0,  1,  0,  1,  1),
   ( 0, -1,  1, -1,  0,  0,  0,  1));


procedure BitBlt(XDest, YDest: word; XSrc: byte);
begin

 asm
   fxs FX_MEMS #$80
 end;

 hlp:=blocks + XSrc;

 blt.src_adr.byte2 := hlp shr 16;
 blt.src_adr.byte1 := hlp shr 8;
 blt.src_adr.byte0 := hlp;

 hlp:=vram + XDest + YDest*320;

 blt.dst_adr.byte2 := hlp shr 16;
 blt.dst_adr.byte1 := hlp shr 8;
 blt.dst_adr.byte0 := hlp;
 
 blt.blt_height:=16-1;

 blt.blt_width:=16-1;

 blt.blt_and_mask:=$ff;

 asm
   fxs FX_MEMS #$00
 end;

 RunBCB(blt);
 while BlitterBusy do;

end;


procedure PutBitmap(X, Y: word; DX, DY, Offset: byte; ID: byte);
begin

 asm
   fxs FX_MEMS #$80
 end;

 hlp:=bmp;

 blt.src_adr.byte2 := hlp shr 16;
 blt.src_adr.byte1 := hlp shr 8;
 blt.src_adr.byte0 := hlp;

 hlp:=vram + 88 * 320;

 blt.dst_adr.byte2 := hlp shr 16;
 blt.dst_adr.byte1 := hlp shr 8;
 blt.dst_adr.byte0 := hlp;
 
 blt.blt_height:=240-1;

 blt.blt_width:=320-1;

 blt.blt_and_mask:=$ff;

 asm
   fxs FX_MEMS #$00
 end;

 RunBCB(blt);
 while BlitterBusy do;

end;


procedure ClearArea(X, Y: word; DX, DY: byte; clr: Boolean);
begin

 asm
   fxs FX_MEMS #$80
 end;

 hlp:=bmp + X + (Y-88)*320;

 blt.src_adr.byte2 := hlp shr 16;
 blt.src_adr.byte1 := hlp shr 8;
 blt.src_adr.byte0 := hlp;

 hlp:=vram + X+Y*320;

 blt.dst_adr.byte2 := hlp shr 16;
 blt.dst_adr.byte1 := hlp shr 8;
 blt.dst_adr.byte0 := hlp;

 blt.blt_height:=DY-1;

 blt.blt_width:=DX-1;

 if clr then
  blt.blt_and_mask:=$00
 else
  blt.blt_and_mask:=$ff;

 asm
   fxs FX_MEMS #$00
 end;

 RunBCB(blt);
 while BlitterBusy do;

end;


procedure DrawBox(X, Y: word);
begin

 asm
   fxs FX_MEMS #$80
 end;

 hlp:=bmp + X + (Y-88)*320;

 blt.src_adr.byte2 := hlp shr 16;
 blt.src_adr.byte1 := hlp shr 8;
 blt.src_adr.byte0 := hlp;

 hlp:=vram + X+Y*320;

 blt.dst_adr.byte2 := hlp shr 16;
 blt.dst_adr.byte1 := hlp shr 8;
 blt.dst_adr.byte0 := hlp;

 blt.blt_height:=16-1;

 blt.blt_width:=16-1;

 blt.blt_and_mask:=$ff;

 asm
   fxs FX_MEMS #$00
 end;

 RunBCB(blt);
 while BlitterBusy do;

end;


procedure PutElement(X, Y: word; Figure: byte);
begin
  if ColoredFigures then
    BitBlt(X, Y, 16 * (Figure div 4))
  else
    BitBlt(X, Y, 128);
end;


procedure XpYp(X, Y: word; Figure, i: byte);
begin

   case Tetromino[Figure, i] of
    -2: Xp := X - 32;
    -1: Xp := X - 16;
     0: Xp := X;
     1: Xp := X + 16;
     2: Xp := X + 32;     
   end;
   
   inc(i);

   case Tetromino[Figure, i] of
    -2: Yp := Y - 32;
    -1: Yp := Y - 16;
     0: Yp := Y;
     1: Yp := Y + 16;
     2: Yp := Y + 32;     
   end;

end;


procedure PutBlock(X, Y: word; Figure: byte);
var
  i: Byte;
begin

  for i := 0 to 3 do begin

    XpYp(X, Y, Figure, i*2);

//    Xp := 16 * Tetromino[Figure, byte(2 * i)] + X;
//    Yp := 16 * Tetromino[Figure, byte(2 * i + 1)] + Y;

    PutElement(Xp, Yp, Figure);
  end;

end;


procedure EraseBlock(X, Y: word; Figure: byte);
var
  i: Byte;
begin

  for i := 0 to 3 do begin
  
   XpYp(X, Y, Figure, i*2);

//    Xp := 16 * Tetromino[Figure, byte(2 * i)] + X;
//    Yp := 16 * Tetromino[Figure, byte(2 * i + 1)] + Y;

    DrawBox(Xp, Yp);
  end;

end;


procedure DrawGrid;
var
  X, Y: Byte;
begin

  for Y := 0 to 19 do
    for X := 0 to 9 do
      if GridS[Y, X] = 1 then
        PutElement(8 + 16 * X, 8 + 16 * Y, GridN[Y, X])
      else
        DrawBox(8 + 16 * X, 8 + 16 * Y)
end;


procedure Status;
begin

  ClearArea(29*8, 88+88+8, 8*8, 8, true);
  vbxe.TextOut(29*8, 88+8, IntToStr(Score));

  ClearArea(29*8, 88+88+32+8, 8*8, 8, true);
  vbxe.TextOut(29*8, 88+32+8, IntToStr(Level+1));

  ClearArea(29*8, 88+88+64+8, 8*8, 8, true);
  vbxe.TextOut(29*8, 88+64+8, IntToStr(Lines));

end;


procedure ShowNextFigure;
begin
  ClearArea(216, 88, 96, 80, false);
  PutBlock(260, 112, FigureB);
end;


procedure ParseKeys;
var
  i: Byte;
  joy, joy_old: byte;
  joy_delay: word;

 procedure isPaused;
 begin
 
   if Paused then begin

      ClearArea(6*8, 88+120, 11*8, 16, false);
      Paused := FALSE;

   end;

 end;
   
  
begin

  if strig0 = 0 then Paused := TRUE;

  joy := joy_1;

  
    if joy = joy_old then begin

     inc(joy_delay);

     if joy_delay <  400 - 30 * (Level mod 10) then exit;
    
    end;
    
    joy_delay:=0;
  
    joy_old := joy;


    case joy of
    
      joy_left:
           begin
      
             isPaused;

             X := X - 1;
             for i := 0 to 3 do
               if (shortint(Tetromino[Figure, byte(2 * i)] + X) < 0) or
                  (GridS[byte(Tetromino[Figure, byte(2 * i + 1)] + Y), byte(Tetromino[Figure, byte(2 * i)] + X)] = 1)
               then
                 X := X + 1;
           end;

      joy_right: 
           begin

             isPaused;

             X := X + 1;
             for i := 0 to 3 do
               if (shortint(Tetromino[Figure, byte(2 * i)] + X) > 9) or
                  (GridS[byte(Tetromino[Figure, byte(2 * i + 1)] + Y), byte(Tetromino[Figure, byte(2 * i)] + X)] = 1)
               then
                 X := X - 1;
           end;

      joy_up:
           begin

             isPaused;

             Figure := Figure + 1;
             if Figure mod 4 = 0 then Figure := Figure - 4;
             for i := 0 to 3 do
               if (shortint(Tetromino[Figure, byte(2 * i)] + X) < 0) or (shortint(Tetromino[Figure, byte(2 * i)] + X) > 9) or
                  (shortint(Tetromino[Figure, byte(2 * i + 1)] + Y) < 0) or (shortint(Tetromino[Figure, byte(2 * i + 1)] + Y) > 19) or
                  (GridS[byte(Tetromino[Figure, byte(2 * i + 1)] + Y), byte(Tetromino[Figure, byte(2 * i)] + X)] = 1)
               then
                 if Figure mod 4 = 0 then
                   Figure := Figure + 3
                 else
                   Figure := Figure - 1;
          end;

      joy_down:
           begin

             isPaused;
	   
             DelayVal := 0;
 	   
	   end;
	   
    end;
    

    if (X <> OldX) or (Y <>OldY) or (OldNo <> Figure) then begin

     EraseBlock(8 + 16 * OldX, 8 + 16 * OldY, OldNo);
     PutBlock(8 + 16 * X, 8 + 16 * Y, Figure);
   
     OldX  := X;
     OldY  := Y;
     OldNo := Figure;

    end; 
     
end;


procedure EraseLines;
var
  N: array [0..4] of Byte;
  Ok, i, J, Num: Byte;
begin

  N[0]:=0;
  N[1]:=0;
  N[2]:=0;
  N[3]:=0;
  N[4]:=0;

  Ok := 0;
  Num := 0;

  for J := 0 to 19 do
  begin
    Ok := 0;
    for i := 0 to 9 do
      if GridS[J, i] = 0 then Ok := 1;
      if Ok = 0 then
      begin
        Num := Num + 1;
        N[Num]:=J;
      end;
  end;

  for J := 1 to Num do
  begin
    for i := N[J] downto 1 do
    begin
      Move(GridS[byte(i - 1)], GridS[i], 10);
      Move(GridN[byte(i - 1)], GridN[i], 10);
    end;
    DrawGrid;
  end;

  if Num > 0 then
  begin
    Lines := Lines + Num;

//    if UseSound then
//      MMSystem.PlaySound(MAKEINTRESOURCE(120), HInstance, SND_ASYNC or SND_RESOURCE);

    if Lines > byte(10 * (StoreLines div 10) + 9) then
    begin
      if (AutoLevel) and (Level < 9) then Level := Level + 1;
      StoreLines := Lines;
      SlideNo := SlideNo + 1;
      if SlideNo mod 5 = 0 then SlideNo := SlideNo - 5;
    end;
  end;

//  if UseSound then
//    MMSystem.PlaySound(MAKEINTRESOURCE(110), HInstance, SND_ASYNC or SND_RESOURCE);

end;


procedure InitGame;
begin
  Level := 0;	// 0..9
  Score := 0;
  Lines := 0;
  StoreLines := 0;
  Randomize;
  Ok := 0;
  FillChar(GridS, SizeOf(GridS), 0);
  FillChar(GridN, SizeOf(GridN), 0);
  SlideNo := 0;

  AutoLevel := TRUE;
  ColoredFigures := TRUE;


  PutBitmap(178, 8, 176, 113, 176 * SlideNo, 2); 
  DrawGrid;

  SetColor(16);

  vbxe.Line(6,0, 6, 239);	 // left edge
  vbxe.Line(7,0, 7, 239);

  vbxe.Line(8+160,0, 8+160, 239); // right edge
  vbxe.Line(9+160,0, 9+160, 239);


  ClearArea(29*8, 88+88, 8*8, 16, true);
  vbxe.TextOut(29*8,88, 'Score:');

  ClearArea(29*8, 88+88+32, 8*8, 16, true);
  vbxe.TextOut(29*8, 88+32, 'Level:');

  ClearArea(29*8, 88+88+64, 8*8, 16, true);
  vbxe.TextOut(29*8, 88+64, 'Lines:');

  vbxe.TextOut(30*8, 29*8, 'Mad Pascal');

  Status;
  
end;


procedure ExitGame;
begin
  Halt(0);
end;


procedure InitVGA;
var i, j: byte;
begin

 if VBXE.GraphResult <> VBXE.grOK then begin
  writeln('VBXE not detected');
  halt;
 end;

 SetHorizontalRes(VBXE.VGAMed);
 ColorMapOff;

 VBXEControl(vc_xdl+vc_xcolor+vc_no_trans);

 SetTopBorder(1);
 SetXDLHeight(240);

 vbxe.VideoRAM := vram+88*320;	// VBXE video ram address

 SetOverlayAddress(vbxe.VideoRAM);

 vbxe_ram.position:=vram;
 vbxe_ram.size:=vram + (240+88) * 320;
 vbxe_ram.clear;

 dmactl:=0;


 asm
  fxs FX_MEMS #$80
 end;

 fillByte(blt, sizeof(TBCB), 0);


 blt.dst_adr.byte2:=vram shr 16;

 blt.dst_step_y:=320;

 blt.src_step_y:=320;

 blt.src_step_x:=1;
 blt.dst_step_x:=1;

 blt.blt_control := 0;

 blt.blt_and_mask:=$ff;


 asm
  fxs FX_MEMS #$00
 end;


 pause;

{
 asm
  sei
  lda #0
  sta nmien
  sta irqen

  lda #$fe
  sta portb

  mwa #NMI $fffa

  mva #$40 nmien
 end;
}

end;


function Randomizer: Byte;
var history: byte;
begin

 While Result = history do Result := 4 * Random(7);
 
 history := Result;
 
end;


begin

  InitVGA;

  repeat
    InitGame;

    repeat
    
      X := 4;
      Y := 1;
      OldX := 4;
      OldY := 1;
      DelayVal := 34 - 3 * (Level mod 10);


      FigureB := Randomizer;	

      ShowNextFigure;

      Figure := FigureA;
      OldNo := Figure;
      FigureA := FigureB;

      repeat
	
	mem[$12]:=$00;	// rtclock
	mem[$13]:=$00;
	mem[$14]:=$00;

        MS := GetTickCount + DelayVal;
        repeat
	
	 ParseKeys;

        until GetTickCount >= MS;


	//Pause;

        if not Paused then
        begin
	
            ParseKeys;

            Ok := 0;
            Y := Y + 1;
            for i := 0 to 3 do
              if (shortint(Tetromino[Figure, byte(2 * i + 1)] + Y) > 19) or
                 (GridS[byte(Tetromino[Figure, byte(2 * i + 1)] + Y), byte(Tetromino[Figure, byte(2 * i)] + X)] = 1)
            then
            begin
              Y := Y - 1;
              Ok := 1;
            end;


	    if (X <> OldX) or (Y <> OldY) or (OldNo <> Figure) then begin

              EraseBlock(8 + 16 * OldX, 8 + 16 * OldY, OldNo);
              PutBlock(8 + 16 * X,  8 + 16 * Y, Figure);  
	    	    
              OldX  := X;
              OldY  := Y;
	    
              OldNo := Figure;

	    end;


        end else begin

         ClearArea(6*8, 88+120, 11*8, 16, true);
         vbxe.TextOut(9*8, 124, 'PAUSE');
	 	 
	end; 


      until Ok = 1;

      Score := Score + 15 + 5 * (Level mod 10);
      Ok := 0;
      for i := 0 to 3 do
      begin
        GridS[byte(Tetromino[Figure, byte(2 * i + 1)] + Y), byte(Tetromino[Figure, byte(2 * i)] + X)] := 1;
        GridN[byte(Tetromino[Figure, byte(2 * i + 1)] + Y), byte(Tetromino[Figure, byte(2 * i)] + X)] := Figure;
      end;
      for i := 0 to 3 do
        if shortint(Tetromino[Figure, byte(2 * i + 1)] + Y) = 1 then Ok := 1;

      EraseLines;
      Status;
    until Ok = 1;


    ClearArea(6*8, 88+120, 11*8, 16, true);    
    vbxe.TextOut(7*8, 124, 'GAME OVER');

    while strig0 <> 0 do;
    

    //if Ok = 1 then ExitGame;

  until FALSE;
end.
