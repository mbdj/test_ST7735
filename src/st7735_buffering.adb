with HAL.Bitmap;
with STM32.GPIO;

package body ST7735_Buffering is



	----------------
	-- Initialize --
	----------------

	procedure Initialize  (ST7735      :  in out ST7735_Buffering) is

		Max_Dim, Min_Dim : Natural;  --  dimensions max et min de l'écran

	begin

		--  Le driver ST7735 considère que l'écran est en format PORTRAIT
		--  C'est pourquoi ici on redresse les dimensions
		--  si jamais elles ont été passées à l'envers
		if (ST7735.Width > ST7735.Height) then
			Max_Dim := ST7735.Width;
			Min_Dim := ST7735.Height;
		else
			Max_Dim := ST7735.Height;
			Min_Dim := ST7735.Width;
		end if;


		Initialise_SPI (SPI      => ST7735.Choix_SPI,
						SPI_SCK  => STM32.GPIO.GPIO_Point (ST7735.SPI_SCK.all),
						SPI_MISO => STM32.GPIO.GPIO_Point (ST7735.SPI_MISO.all),
						SPI_MOSI => STM32.GPIO.GPIO_Point (ST7735.SPI_MOSI.all),
						PIN_RS   => STM32.GPIO.GPIO_Point (ST7735.RS.all),
						PIN_RST  => STM32.GPIO.GPIO_Point (ST7735.RST.all),
						PIN_CS   => STM32.GPIO.GPIO_Point (ST7735.CS.all));

		ST7735.BitMap_Buffer := new Memory_Mapped_Bitmap.Memory_Mapped_Bitmap_Buffer;
		ST7735.Pixel_Data_BitMap_Buffer := new HAL.UInt16_Array (1 .. (Max_Dim * Min_Dim));

		--
		--  séquence d'initialisation de l'écran ST7735 décrite ici :
		--  https://github.com/AdaCore/Ada_Drivers_Library/blob/master/boards/OpenMV2/src/openmv-lcd_shield.adb
		--

		ST7735R.Initialize (LCD => ST7735R.ST7735R_Screen (ST7735));

		ST7735.Set_Memory_Data_Access
		  (	 Color_Order       => (if ST7735.Color_Correction then ST7735R.BGR_Order else ST7735R.RGB_Order),
	  Vertical            => ST7735R.Vertical_Refresh_Top_Bottom,
	  Horizontal          => ST7735R.Horizontal_Refresh_Left_Right,
	  Row_Addr_Order      => ST7735R.Row_Address_Bottom_Top,
	  Column_Addr_Order   => ST7735R.Column_Address_Right_Left,
	  Row_Column_Exchange => False);

		ST7735.Set_Pixel_Format ( ST7735R.Pixel_16bits);

		ST7735.Set_Frame_Rate_Normal (RTN         => 16#01#,
										  Front_Porch => 16#2C#,
										  Back_Porch  => 16#2D#);

		ST7735.Set_Frame_Rate_Idle (RTN         => 16#01#,
										Front_Porch => 16#2C#,
										Back_Porch  => 16#2D#);

		ST7735.Set_Frame_Rate_Partial_Full (RTN_Part         => 16#01#,
												  Front_Porch_Part => 16#2C#,
												  Back_Porch_Part  => 16#2D#,
												  RTN_Full         => 16#01#,
												  Front_Porch_Full => 16#2C#,
												  Back_Porch_Full  => 16#2D#);

		ST7735.Set_Inversion_Control (Normal       => ST7735R.Line_Inversion,
										  Idle         => ST7735R.Line_Inversion,
										  Full_Partial => ST7735R.Line_Inversion);

		ST7735.Set_Power_Control_1 (AVDD => 2#101#,    --  5
										VRHP => 2#0_0010#, --  4.6
										VRHN => 2#0_0010#, --  -4.6
										MODE => 2#10#);    --  AUTO

		ST7735.Set_Power_Control_2 (VGH25 => 2#11#,  --  2.4
										VGSEL => 2#01#,  --  3*AVDD
										VGHBT => 2#01#); --  -10

		ST7735.Set_Power_Control_3 (16#0A#, 16#00#);
		ST7735.Set_Power_Control_4 (16#8A#, 16#2A#);
		ST7735.Set_Power_Control_5 (16#8A#, 16#EE#);
		ST7735.Set_Vcom (16#E#);

		ST7735.Set_Address (X_Start => 0,
							 X_End   => UInt16 (Min_Dim - 1),
							 Y_Start => 0,
							 Y_End   => UInt16 (Max_Dim - 1));

		if ST7735.Color_Correction then
			ST7735.Display_Inversion_On;
		end if;

		ST7735.Turn_On;

		ST7735.Initialize_Layer (Layer  => 1,
									Mode   => HAL.Bitmap.RGB_565,
									X      => 0,
									Y      => 0,
									Width  => Min_Dim,
									Height => Max_Dim);



		--  initialisation de BitMap_Buffer
		--  voir https://github.com/AdaCore/Ada_Drivers_Library/blob/master/boards/OpenMV2/src/openmv-bitmap.adb


		if (ST7735.Orientation = LANDSCAPE) then
			ST7735.BitMap_Buffer.Actual_Width := Max_Dim;  --  inversion pour le mode landscape (sinon Width)
			ST7735.BitMap_Buffer.Actual_Height := Min_Dim;  --  inversion pour le mode landscape (sinon Height)
			ST7735.BitMap_Buffer.Currently_Swapped := True; --  inversion pour le mode landscape (sinon False)
		else
			ST7735.BitMap_Buffer.Actual_Width := Min_Dim;  --  inversion pour le mode landscape (sinon Width)
			ST7735.BitMap_Buffer.Actual_Height := Max_Dim;  --  inversion pour le mode landscape (sinon Height)
			ST7735.BitMap_Buffer.Currently_Swapped := False; --  inversion pour le mode landscape (sinon False)
		end if;

		ST7735.BitMap_Buffer.Actual_Color_Mode := HAL.Bitmap.RGB_565;
		ST7735.BitMap_Buffer.Addr := ST7735.Pixel_Data_BitMap_Buffer.all'Address;

	end Initialize;



	------------
	-- BitMap --
	------------

	function BitMap (ST7735 : in out ST7735_Buffering) return Memory_Mapped_Bitmap.Any_Memory_Mapped_Bitmap_Buffer is
	begin
		return ST7735.BitMap_Buffer;
	end BitMap;



	-------------
	-- Display --
	-------------

	procedure Display (ST7735 : in out ST7735_Buffering) is
	begin
		ST7735.Write_Raw_Pixels (Data =>  ST7735.Pixel_Data_BitMap_Buffer.all);
	end Display;

end ST7735_Buffering;
