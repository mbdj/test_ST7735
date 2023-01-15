with HAL.SPI;

--
-- Mehdi 04/01/2023 --
--
--  Test de l'écran ST7735
--

with Last_Chance_Handler;
pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.


with Ada.Real_Time; use Ada.Real_Time;

--  écran ST7735
--  with ST7735R.RAM_Framebuffer;
with ST7735R;

with Bitmapped_Drawing;

with HAL; use HAL;

with HAL.Bitmap;
--  with HAL.Framebuffer;

with Memory_Mapped_Bitmap;

with STM32.Board;
with STM32.Device;
with STM32.GPIO;
with STM32.SPI;

with Ravenscar_Time;
with BMP_Fonts;

procedure Testst7735 is

	--  dimensions de l'écran ST7735
	Width  :  constant Natural := 128;
	Height :  constant Natural := 160;

	--
	--  séquence d'initialisation de l'écran ST7735 décrite ici :
	--  https://github.com/AdaCore/Ada_Drivers_Library/blob/master/boards/OpenMV2/src/openmv-lcd_shield.adb
	--
	procedure Initialise_ST7735 (Ecran  : in out ST7735R.ST7735R_Screen;
										Width  : in Natural := 128;
										Height : in Natural := 160) is
	begin
		Ecran.Initialize;

		Ecran.Set_Memory_Data_Access
		  (	 Color_Order         => ST7735R.RGB_Order,
	  Vertical            => ST7735R.Vertical_Refresh_Top_Bottom,
	  Horizontal          => ST7735R.Horizontal_Refresh_Left_Right,
	  Row_Addr_Order      => ST7735R.Row_Address_Bottom_Top,
	  Column_Addr_Order   => ST7735R.Column_Address_Right_Left,
	  Row_Column_Exchange => False);

		Ecran.Set_Pixel_Format ( ST7735R.Pixel_16bits);

		Ecran.Set_Frame_Rate_Normal (RTN         => 16#01#,
										 Front_Porch => 16#2C#,
										 Back_Porch  => 16#2D#);

		Ecran.Set_Frame_Rate_Idle (RTN         => 16#01#,
									  Front_Porch => 16#2C#,
									  Back_Porch  => 16#2D#);

		Ecran.Set_Frame_Rate_Partial_Full (RTN_Part         => 16#01#,
												 Front_Porch_Part => 16#2C#,
												 Back_Porch_Part  => 16#2D#,
												 RTN_Full         => 16#01#,
												 Front_Porch_Full => 16#2C#,
												 Back_Porch_Full  => 16#2D#);

		Ecran.Set_Inversion_Control (Normal       => ST7735R.Line_Inversion,
										 Idle         => ST7735R.Line_Inversion,
										 Full_Partial => ST7735R.Line_Inversion);

		Ecran.Set_Power_Control_1 (AVDD => 2#101#,    --  5
									  VRHP => 2#0_0010#, --  4.6
									  VRHN => 2#0_0010#, --  -4.6
									  MODE => 2#10#);    --  AUTO

		Ecran.Set_Power_Control_2 (VGH25 => 2#11#,  --  2.4
									  VGSEL => 2#01#,  --  3*AVDD
									  VGHBT => 2#01#); --  -10

		Ecran.Set_Power_Control_3 (16#0A#, 16#00#);
		Ecran.Set_Power_Control_4 ( 16#8A#, 16#2A#);
		Ecran.Set_Power_Control_5 ( 16#8A#, 16#EE#);
		Ecran.Set_Vcom ( 16#E#);

		Ecran.Set_Address (X_Start => 0,
							X_End   => UInt16 (Width - 1),
							Y_Start => 0,
							Y_End   => UInt16 (Height - 1));

		Ecran.Turn_On;

		Ecran.Initialize_Layer (Layer  => 1,
								  Mode   => HAL.Bitmap.RGB_565,
								  X      => 0,
								  Y      => 0 ,
								  Width  => Width,
								  Height => Height);
	end Initialise_ST7735;


	type Choix_SPI is (SPI1, SPI2);

	procedure Initialise_SPI (SPI : Choix_SPI; SPI_SCK, SPI_MISO, SPI_MOSI, PIN_RS, PIN_RST, PIN_CS : in STM32.GPIO.GPIO_Point) is
		SPI_Conf  : STM32.SPI.SPI_Configuration;
		GPIO_Conf : STM32.GPIO.GPIO_Port_Configuration;

		CS_RS_RST_Points  : constant STM32.GPIO.GPIO_Points := (PIN_RS, PIN_RST, PIN_CS);
		SPI_Points      : constant STM32.GPIO.GPIO_Points := (SPI_SCK, SPI_MISO, SPI_MOSI);

	begin
		--
		--  initialiser SPI
		--  voir https://github.com/AdaCore/Ada_Drivers_Library/blob/5ffdf12bec720aea12467229bb5862c465bf0333/boards/OpenMV2/src/openmv.adb#L140
		--

		STM32.Device.Enable_Clock (SPI_Points);

		GPIO_Conf := (Mode           => STM32.GPIO.Mode_AF,
					 AF             => (case SPI is when SPI1 => STM32.Device.GPIO_AF_SPI1_5, when SPI2 => STM32.Device.GPIO_AF_SPI2_5),
					 Resistors      => STM32.GPIO.Pull_Down, --  SPI low polarity
					 AF_Speed       => STM32.GPIO.Speed_100MHz,
					 AF_Output_Type => STM32.GPIO.Push_Pull);

		STM32.GPIO.Configure_IO (SPI_Points, GPIO_Conf);

		STM32.Device.Enable_Clock (case SPI is when SPI1 => STM32.Device.SPI_1, when SPI2 => STM32.Device.SPI_2);

		case SPI is
		when SPI1 => STM32.Device.SPI_1.Disable;
		when SPI2 => STM32.Device.SPI_1.Disable;
		end case;

		SPI_Conf.Direction           := STM32.SPI.D2Lines_FullDuplex;
		SPI_Conf.Mode                := STM32.SPI.Master;
		SPI_Conf.Data_Size           := HAL.SPI.Data_Size_8b;
		SPI_Conf.Clock_Polarity      := STM32.SPI.Low;
		SPI_Conf.Clock_Phase         := STM32.SPI.P1Edge;
		SPI_Conf.Slave_Management    := STM32.SPI.Software_Managed;
		SPI_Conf.Baud_Rate_Prescaler := STM32.SPI.BRP_2;
		SPI_Conf.First_Bit           := STM32.SPI.MSB;
		SPI_Conf.CRC_Poly            := 7;

		case SPI is
		when SPI1 =>
			STM32.Device.SPI_1.Configure (SPI_Conf);
			STM32.Device.SPI_1.Enable;
		when SPI2 =>
			STM32.Device.SPI_2.Configure (SPI_Conf);
			STM32.Device.SPI_2.Enable;
		end case;

		STM32.Device.Enable_Clock (CS_RS_RST_Points);

		GPIO_Conf := (Mode        => STM32.GPIO.Mode_Out,
					 Output_Type => STM32.GPIO.Push_Pull,
					 Speed       => STM32.GPIO.Speed_100MHz,
					 Resistors   => STM32.GPIO.Floating);

		STM32.GPIO.Configure_IO (CS_RS_RST_Points, GPIO_Conf);

	end Initialise_SPI;


	Period       : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (50);
	Next_Release : Ada.Real_Time.Time := Ada.Real_Time.Clock;


	--  Initialisation de l'écran ST7735 en SPI
	--  SPI 1 : SCK connecté sur SCK/SCL PA5 ; SDA connecté à MOSI PA7 ; pas de connexion sur MISO (PA6)
	--  SPI 2 : SCK connecté sur SCK/SCL PB13 ; SDA connecté à MOSI PB15 ; pas de connexion sur MISO (PB14)
	--  CS, RS, RST : à fixer comme on veut
	--  LEDA (pin 8 du ST7735) : rétroéclairage connecté sur VCC (3.3V)

	SPI_SCK  : STM32.GPIO.GPIO_Point renames STM32.Device.PB13; --  PA5;
	SPI_MISO : STM32.GPIO.GPIO_Point renames STM32.Device.PB14; --  PA6; -- pas connecté au ST7735
	SPI_MOSI : STM32.GPIO.GPIO_Point renames STM32.Device.PB15; --  PA7;

	ST7735_RS :  STM32.GPIO.GPIO_Point renames STM32.Device.PB10;  -- register select
	ST7735_RST  : STM32.GPIO.GPIO_Point renames STM32.Device.PA8;  -- reset
	ST7735_CS :  STM32.GPIO.GPIO_Point renames STM32.Device.PB4; -- chip select = SPI2_NSS

	Ecran_ST7735 : ST7735R.ST7735R_Screen (Port   => STM32.Device.SPI_2'Access,
													 CS     => ST7735_CS'Access,
													 RS     => ST7735_RS'Access,
													 RST    => ST7735_RST'Access,
													 Time   => Ravenscar_Time.Delays);

	--  Sans double buffering
	--  BitMap_ST7735 : HAL.Bitmap.Any_Bitmap_Buffer := Ecran_St7735.Hidden_Buffer (Layer => 1); --  bitmap du ST7735 dans laquelle dessiner

	--  BitMap_Buffer pour le double buffering
	--  voir https://github.com/AdaCore/Ada_Drivers_Library/blob/master/boards/OpenMV2/src/openmv-bitmap.adb
	BitMap_Buffer :  constant Memory_Mapped_Bitmap.Any_Memory_Mapped_Bitmap_Buffer := new Memory_Mapped_Bitmap.Memory_Mapped_Bitmap_Buffer;
	subtype Pixel_Data is UInt16_Array (1 .. (Width * Height));
	Pixel_Data_BitMap_Buffer :  constant access Pixel_Data := new Pixel_Data;


	Compteur : Natural := 0; --  compteur affiché sur le ST7735
	PosY     : Natural := 0;

begin

	--  initialisation de BitMap_Buffer
	--  voir https://github.com/AdaCore/Ada_Drivers_Library/blob/master/boards/OpenMV2/src/openmv-bitmap.adb
	BitMap_Buffer.Actual_Width := Height;  --  inversion pour le mode landscape (sinon Width)
	BitMap_Buffer.Actual_Height := Width;  --  inversion pour le mode landscape (sinon Height)
	BitMap_Buffer.Actual_Color_Mode := HAL.Bitmap.RGB_565;
	BitMap_Buffer.Currently_Swapped := True; --  inversion pour le mode landscape (sinon False)
	BitMap_Buffer.Addr := Pixel_Data_BitMap_Buffer.all'Address;

	Initialise_SPI (SPI2, SPI_SCK, SPI_MISO, SPI_MOSI, ST7735_RS, ST7735_RST, ST7735_CS);

	--  Initialiser l'écran TFT ST7735
	Initialise_ST7735 (Ecran_ST7735, Width  => Width, Height => Height);

	--
	--  Remplir 'Écran Avec Une Couleur (fonctionne mais pas efficace)
	--
	--  for X in 0 .. 128 loop
	--  	for Y in 0 .. 160 loop
	--  		Ecran_ST7735.Set_Pixel (X => HAL.UInt16 (X), Y => HAL.UInt16 (Y), Color => 0);
	--  	end loop;
	--  end loop;


	--  Set_Source fixe la couleur de tracé
	BitMap_Buffer.Set_Source (ARGB => HAL.Bitmap.Dark_Magenta);
	BitMap_Buffer.Fill;

	--  BitMap_ST7735.Set_Source (ARGB => HAL.Bitmap.Cyan);
	--  BitMap_ST7735.Draw_Circle (Center => (X => 50, Y => 50) , Radius =>  40);
	--
	--  BitMap_ST7735.Set_Source (ARGB => HAL.Bitmap.Violet);
	--  BitMap_ST7735.Draw_Line (Start => (20, 20), Stop => (100, 80), Thickness => 3);


	--  tracer un trait -- fonctionne mais pas efficace
	--  for Y in 10 .. 100 loop
	--  	Ecran_ST7735.Set_Pixel (X => 20, Y => HAL.UInt16 (Y), Color => 31);  -- Color au format RGB 565 : R sur 5bits G sur 6 bits B sur 5 bits
	--  end loop;


	--  initialiser la led utilisateur verte
	STM32.Board.Initialize_LEDs; -- utiliser uniquement avec le ST7735 sur SPI2 car les pins PA5,PA6,PA7 de SPI1 sont utilisées pour les LED
	STM32.Board.Turn_On (STM32.Board.Green_LED);


	STM32.Board.Turn_Off (STM32.Board.Green_LED);

	loop
		STM32.Board.Toggle (STM32.Board.Green_LED);

		--  écriture sur le ST7735
		--  nb : il faut redessiner toute l'image à chaque fois
		BitMap_Buffer.Set_Source (ARGB => HAL.Bitmap.Dark_Magenta);
		BitMap_Buffer.Fill;
		Bitmapped_Drawing.Draw_String (BitMap_Buffer.all,
											Start      => (40, 40),
											Msg        => ("NEW TEST FSF 12"),
											Font       => BMP_Fonts.Font8x8,
											Foreground => HAL.Bitmap.Red,
											Background => HAL.Bitmap.Green);

		Bitmapped_Drawing.Draw_String (BitMap_Buffer.all,
											Start      => (30, PosY),
											Msg        => (Compteur'Image),
											Font       => BMP_Fonts.Font12x12,
											Foreground => HAL.Bitmap.Green_Yellow,
											Background => HAL.Bitmap.Blue);

		PosY := (if PosY > Width  then 0 else PosY + 1);


		BitMap_Buffer.Set_Source (ARGB => HAL.Bitmap.Cyan);
		BitMap_Buffer.Draw_Circle (Center => (X => 40, Y => 50) , Radius =>  40);

		Ecran_ST7735.Write_Raw_Pixels (Data =>  Pixel_Data_BitMap_Buffer.all);

		Compteur := Compteur + 1 ;

		Next_Release := Next_Release + Period;
		delay until Next_Release;

	end loop;

end Testst7735;
