'****************************************************************
'*  Name    : KeyBuster RFID 2nd Generation                                     
'*  Author  : [Sam and Kim Bozman]                    
'*  Notice  : Copyright (c) 2008 [Sam and Kim Bozman] 
'*          : All Rights Reserved                               
'*  Date    : 31/12/2008                                        
'*  Version : 1.0                                               
'*  Notes   : Added "Read Tag"  31/12/2008                                                
'*  Revision: Cleaning up code Oct 24/09                                                  
'****************************************************************
 Include "INC\Initialize.inc"
'----------------- User ID and Tag variables and symbols --------------------------------------
Dim User_Pointer As Word       'Variable to hold 2 byte pointer to next empty (16 byte) user/tag spot in program memory.

Rem FWD Symbol SD_CS = PORTC.2          'Slave Select [SS](SD pin 1)
Rem FWD Symbol SD_DI = PORTC.5          'Master Out/Slave In [MOSI] (SD Pin 2)
Rem FWD Symbol SD_CLK = PORTC.3         'Clock  (SD Pin 5)
Rem FWD Symbol SD_DO = PORTC.4          'Master In Slave Out [MISO] (SD Pin 7)
Symbol SD_Detect = PORTA.1     'A GND is used to detect an fully inserted SD Card
Symbol RFIDEnable = PORTD.4	  'When high the RFID reader is active 
Symbol BUA = 0X9C50          'Start of User Table Address in Flash (program memory) where User numbers and Tag numbers are stored.
Symbol UPA_L = 0X000           ' Address in EEProm where low byte of User Pointer is stored
Symbol UPA_H = 0X001            'Address in EEProm where high byter of User Pointer is stored.
Symbol NOU = 0X002              'Address in EEProm where total # of Users is stored
Symbol num_UHE = 0X003                 'Address in EEProm where number of User history entries is stored
Symbol num_MHE = 0X004                  'Address in EEProm where number of Manager history entries is stored
Symbol TagOffset = 4            'Offset from start of User address over user number to Tag number
Dim TagIn[10] As Byte		'VARIABLE array used for Tag ID
Dim UserIn[4] As Byte       'Variable array used for User ID number
Dim UTag[16] As Byte        'Variable used to hold a combination of User ID and Tag ID

'---------------- User History variables and Symbols ------------------------------------------
Symbol UHA = 0X010              'Beginning address in EEprom used to store 4 digit User ID History
Symbol MHA = 0X390               'Beginning address in EEprom used to store 8 digit Manager ID and date.
Symbol num_UH = 200              'Maximum User History.. Keeps track of last 200 users
Symbol num_MH = 10               'Maximum Manager History...Keeps track of last 10 Managers and dates of changes.
'-----------------------------------------------------------------------------------------------
Dim ModNum[7] As Byte       'Used to store Module number located at 0X9C40 in program memory.
Dim Response As Byte         'Temporary Byte variable

Dim MyCount As Byte          'Used for looping
Dim Index As Byte           'Used for looping
Dim Index2 As Byte          'Used for looping
Dim TV1 As Byte             'Temporary Byte variable
Dim Word_Var As Word        'Temporary Word Variable
Dim MyNum As String * 3
'------------------   Initialize     -----------------------
 DelayMS 200               'Allow chip to settle

Input SD_Detect           'Set SD Detect port as input...  (PORTA.1 Initialize module) 
Low RFIDEnable		              ' Turn off RFID Reader     (PORTD.4 Initialize module)

User_Pointer.LowByte = ERead UPA_L    'Read the low and high bytes of...
User_Pointer.HighByte = ERead UPA_H    'user pointer address from EEprom

If User_Pointer = 0XFFFF Then             'If the value read from EEprom is OXFFFF then this is a new chip so....
    User_Pointer = BUA                   '...we write the low and ..
    EWrite UPA_L, [User_Pointer.LowByte]  '...high bytes of the base user address (0X9C500...
    EWrite UPA_H, [User_Pointer.HighByte]  '...into the EEProm Pointer storage spot (0X000 and 0X001)
    EWrite num_UHE, [0X00]              'Initialize number of User histories to zero
    EWrite num_MHE, [0X00]               'Initialize number of Manager histories to zero
EndIf


 
 If SD_Detect = 0 Then
    Cls
    Print "Detected!"
    Pause 3000
    GoSub Init_SD  '************ Only do one time when SD card detected.
    GoSub Read_SD   'This sub reads and writes users and managers to memory
 Else
    GoSub Init_SD  '************ Only do one time when SD card detected.
 End If 
 
 '=================   Main Program   =======================
   
 GoSub Write_Users_SD
 Cls
 Print "Done"
 
 
  
  Pause 3000
  Start:
  'Cls
  'Print "Starting..."
  'Pause 3000
 
 Start2: 
  GoSub Read_Tag
  
  Cls
 Print "Checking TAG"
               ' Pause 2000
  GoSub Check_Tag
  If Response = 1 Then
    Cls
    Print At 1,1, "Got a match"
    Print At 2,1, Str UserIn
    GoSub WriteH
    Cls
    Print "History DONE!"
  Pause 2000
   GoTo Start2
  Else
    Cls
    Print "No Match"
    Pause 2000
    GoTo Start2
  EndIf
  Stop
  
 '------------ Includes -------------------------------------
 Include "INC\Read Tag.inc"
 Include "INC\Read SD.inc"
 Include "INC\Write SD.inc"
 Include "INC\Init SD.inc"
 Include "INC\Check Tag.inc"
 Include "INC\Write_U_H.inc"
 Include "INC\Write_M_H.inc"
 Include "INC\Write_M_SD.inc"
 Include "INC\Write_Users_SD.inc"
 Include "INC\Read_Mod.inc"
 Include "INC\GoSleep.inc"
 '-------------------- Module Number ------------------------
 Org 0X9C40            'This is the Address where the Module ID number will be stored
 CData "A27B83B", 0    ' ****** This is the unique module number for the module. ******