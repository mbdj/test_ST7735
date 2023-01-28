with STM32.SPI;
with STM32.Device;
with HAL.SPI;

package body SPI is

	procedure Initialise_SPI (SPI                     : in Choix_SPI;
									SPI_SCK, SPI_MISO, SPI_MOSI,
									PIN_RS, PIN_RST, PIN_CS : in STM32.GPIO.GPIO_Point) is
		SPI_Conf  : STM32.SPI.SPI_Configuration;
		GPIO_Conf : STM32.GPIO.GPIO_Port_Configuration;

		CS_RS_RST_Points  : constant STM32.GPIO.GPIO_Points := [PIN_RS, PIN_RST, PIN_CS];
		SPI_Points        : constant STM32.GPIO.GPIO_Points := [SPI_SCK, SPI_MISO, SPI_MOSI];

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


end SPI;
