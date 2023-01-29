with ST7735R;
with Memory_Mapped_Bitmap;
with HAL; use HAL;
with STM32.GPIO;
with SPI; use SPI;


package ST7735_Buffering is
--  driver pour un écran ST7735 avec buffer
--
--  principe :
--   1- Initialiser l'écran avec Initialise()
--   2- Dessiner dans le buffer accessible par la fonction BitMap()
--   3- Afficher sur l'écran physique avec Display
--
--  Il faut refaire le dessin complet avant chaque Display
--

	type ST7735_Buffering is limited new ST7735R.ST7735R_Screen with private;

	type Type_Orientation is (LANDSCAPE, PORTRAIT);

	--  initialisation de l'écran et du buffer
	procedure Initialize (ST7735       : in out ST7735_Buffering;
							  Choix_SPI    : in SPI.Choix_SPI;
							  SPI_SCK      : in STM32.GPIO.GPIO_Point;
							  SPI_MISO     : in STM32.GPIO.GPIO_Point;
							  SPI_MOSI     : in STM32.GPIO.GPIO_Point;
							  PIN_RS       : in out STM32.GPIO.GPIO_Point;
							  PIN_RST      : in out STM32.GPIO.GPIO_Point;
							  PIN_CS       : in out STM32.GPIO.GPIO_Point;
							  Width        : in Natural := 128;  --  les spécifications du ST7735 sont données en orientation portrait
							  Height       : in Natural := 160;  --  les spécifications du ST7735 sont données en orientation portrait
							  Orientation  : in Type_Orientation := LANDSCAPE);

	--  retourne la bitmap sur laquelle on peut dessiner
 --  pour écrire : utiliser le package Bitmapped_Drawing
 --  pour dessiner : utiliser le package HAL.Bitmap
	function BitMap (ST7735 : in out ST7735_Buffering) return Memory_Mapped_Bitmap.Any_Memory_Mapped_Bitmap_Buffer;

	--  après avoir dessiner sur la bitmap il faut appeler Display pour afficher sur l'écran physique
	procedure Display (ST7735 : in out ST7735_Buffering);

private

	--  type ST7735_Buffering is record
	type ST7735_Buffering is limited new ST7735R.ST7735R_Screen with record
		Choix_SPI    :  SPI.Choix_SPI;
		SPI_SCK      :  STM32.GPIO.GPIO_Point;
		SPI_MISO     :  STM32.GPIO.GPIO_Point;
		SPI_MOSI     :  STM32.GPIO.GPIO_Point;
		PIN_RS       :  STM32.GPIO.GPIO_Point;
		PIN_RST      :  STM32.GPIO.GPIO_Point;
		PIN_CS       :  STM32.GPIO.GPIO_Point;
		Width        :  Natural := 128;
		Height       :  Natural := 160;


		--  BitMap_Buffer pour le double buffering
		--  voir https://github.com/AdaCore/Ada_Drivers_Library/blob/master/boards/OpenMV2/src/openmv-bitmap.adb
		BitMap_Buffer            : Memory_Mapped_Bitmap.Any_Memory_Mapped_Bitmap_Buffer;
		Pixel_Data_BitMap_Buffer : access HAL.UInt16_Array ;
	end record;

end ST7735_Buffering;
