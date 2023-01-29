--
-- Mehdi 28/01/2023 --
--
--  Test de l'écran ST7735
--

with Last_Chance_Handler;
pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.


with Ada.Real_Time; use Ada.Real_Time;

with SPI;

with ST7735_Buffering; use ST7735_Buffering;

with Bitmapped_Drawing;

with HAL;
with HAL.Bitmap;

with STM32.Board;
with STM32.Device;

with Ravenscar_Time;
with BMP_Fonts;

procedure Testst7735 is
----------------------------------------------------
	function Min (A, B : in Natural) return Natural is (if A > B then B else A);


	function Max (A, B : in Natural) return Natural is (if A > B then A else B);

	----------------------------------------------------

	--  dimensions de l'écran ST7735
	Width       :  constant Natural := 128;
	Height      :  constant Natural := 160;
	Orientation : constant Type_Orientation := PORTRAIT;


	Period       : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds (50);
	Next_Release : Ada.Real_Time.Time := Ada.Real_Time.Clock;


	Ecran_ST7735 : ST7735_Buffering.ST7735_Buffering (Port   => STM32.Device.SPI_2'Access,
																	CS     => STM32.Device.PB4'Access,
																	RS     => STM32.Device.PB10'Access,
																	RST    => STM32.Device.PA8'Access,
																	Time   => Ravenscar_Time.Delays);

	Compteur : Natural := 0; --  compteur affiché sur le ST7735
	PosY     : Natural := 0; --  position où on affiche le compteur

begin

	--  Initialiser l'écran TFT ST7735
	Ecran_ST7735.Initialize (Choix_SPI    => SPI.SPI2,
								  SPI_SCK      => STM32.Device.PB13,
								  SPI_MISO     => STM32.Device.PB14,
								  SPI_MOSI     => STM32.Device.PB15,
								  PIN_RS       => STM32.Device.PB10,
								  PIN_RST      => STM32.Device.PA8,
								  PIN_CS       => STM32.Device.PB4,
								  Width        => Width,
								  Height       => Height,
								  Orientation  => Orientation);


	--  Set_Source fixe la couleur de tracé
	Ecran_ST7735.BitMap.Set_Source (ARGB => HAL.Bitmap.Dark_Magenta);
	Ecran_ST7735.BitMap.Fill;

	--  initialiser la led utilisateur verte
	STM32.Board.Initialize_LEDs; -- utiliser uniquement avec le ST7735 sur SPI2 car les pins PA5,PA6,PA7 de SPI1 sont utilisées pour les LED
	STM32.Board.Turn_On (STM32.Board.Green_LED);

	loop
		STM32.Board.Toggle (STM32.Board.Green_LED);

		--  écriture sur le ST7735
		--  nb : il faut redessiner toute l'image à chaque fois
		--  il faut dessiner dans la BitMap puis afficher sur l'écran physique avec Display
		Ecran_ST7735.BitMap.Set_Source (ARGB => HAL.Bitmap.Dark_Magenta);
		Ecran_ST7735.BitMap.Fill;
		Bitmapped_Drawing.Draw_String (Ecran_ST7735.BitMap.all,
											Start      => (40, 40),
											Msg        => ("ST7735"),
											Font       => BMP_Fonts.Font8x8,
											Foreground => HAL.Bitmap.Red,
											Background => HAL.Bitmap.Green);

		Bitmapped_Drawing.Draw_String (Ecran_ST7735.BitMap.all,
											Start      => (30, PosY),
											Msg        => (Compteur'Image),
											Font       => BMP_Fonts.Font12x12,
											Foreground => HAL.Bitmap.Green_Yellow,
											Background => HAL.Bitmap.Blue);
		declare
			Hauteur : Integer := (if Orientation = LANDSCAPE then Min (Width, Height) else Max (Width, Height));
		begin
			PosY := (if PosY > Hauteur then 0 else PosY + 1);
		end;

		Ecran_ST7735.BitMap.Set_Source (ARGB => HAL.Bitmap.Cyan);
		Ecran_ST7735.BitMap.Draw_Circle (Center => (X => 40, Y => 50) , Radius =>  40);

		--  affiche sur l'écran physique ce qui a été dessiné sur la bitmap
		Ecran_ST7735.Display;

		Compteur := Compteur + 1 ;

		Next_Release := Next_Release + Period;
		delay until Next_Release;

	end loop;

end Testst7735;
