with HAL.Time;
with ST7735R;
with Memory_Mapped_Bitmap;
with HAL; use HAL;
with SPI; use SPI;
with HAL.SPI; use HAL.SPI;
with HAL.GPIO; use HAL.GPIO;


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

	type Type_Orientation is (LANDSCAPE, PORTRAIT);


	type ST7735_Buffering
	  (Port                : not null Any_SPI_Port;
	 CS                  : not null Any_GPIO_Point;
	 RS                  : not null Any_GPIO_Point;
	 RST                 : not null Any_GPIO_Point;
	 Time                : not null HAL.Time.Any_Delays;
	 Choix_SPI           :  SPI.Choix_SPI;
	 SPI_SCK             :  not null Any_GPIO_Point;
	 SPI_MISO            :  not null Any_GPIO_Point;
	 SPI_MOSI            :  not null Any_GPIO_Point;
	 Width               :  Natural;
	 Height              :  Natural;
	 Orientation         :  Type_Orientation;
	 Color_Correction    :  Boolean)
	is limited new ST7735R.ST7735R_Screen with private;


	--  initialisation de l'écran et du buffer
	procedure Initialize (ST7735 : in out ST7735_Buffering);

	--  retourne la bitmap sur laquelle on peut dessiner
	--  pour écrire : utiliser le package Bitmapped_Drawing
	--  pour dessiner : utiliser le package HAL.Bitmap
	function BitMap (ST7735 : in out ST7735_Buffering) return Memory_Mapped_Bitmap.Any_Memory_Mapped_Bitmap_Buffer;

	--  après avoir dessiner sur la bitmap il faut appeler Display pour afficher sur l'écran physique
	procedure Display (ST7735 : in out ST7735_Buffering);

private

	--  type ST7735_Buffering is record
	type ST7735_Buffering
	  (Port                : not null Any_SPI_Port;
	 CS                  : not null Any_GPIO_Point;
	 RS                  : not null Any_GPIO_Point;
	 RST                 : not null Any_GPIO_Point;
	 Time                : not null HAL.Time.Any_Delays;
	 Choix_SPI           :  SPI.Choix_SPI;
	 SPI_SCK             :  not null Any_GPIO_Point;
	 SPI_MISO            :  not null Any_GPIO_Point;
	 SPI_MOSI            :  not null Any_GPIO_Point;
	 Width               :  Natural;
	 Height              :  Natural;
	 Orientation         :  Type_Orientation;
	 Color_Correction    :  Boolean)
	is limited new ST7735R.ST7735R_Screen
	  (Port         => Port,
	 CS           => CS,
	 RS           => RS,
	 RST          => RST,
	 Time         => Time)
	with record
	--  BitMap_Buffer pour le double buffering
	--  voir https://github.com/AdaCore/Ada_Drivers_Library/blob/master/boards/OpenMV2/src/openmv-bitmap.adb
		BitMap_Buffer            : Memory_Mapped_Bitmap.Any_Memory_Mapped_Bitmap_Buffer;
		Pixel_Data_BitMap_Buffer : access HAL.UInt16_Array ;
	end record;

end ST7735_Buffering;
