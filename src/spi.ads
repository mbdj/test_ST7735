with STM32.GPIO;

package SPI is

	type Choix_SPI is (SPI1, SPI2);

	procedure Initialise_SPI (SPI                     : in Choix_SPI;
									SPI_SCK, SPI_MISO, SPI_MOSI,
									PIN_RS, PIN_RST, PIN_CS : in STM32.GPIO.GPIO_Point);

end SPI;
