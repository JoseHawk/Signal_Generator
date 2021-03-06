-- GENERADOR DE SENIALES

-- Librerias necesarias
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

-- Definimos la entidad
ENTITY Generador_seniales IS

	PORT (
	
		-- Entradas de las distintas opciones seleccionables y el reloj
		reloj : IN STD_LOGIC;
		formaOnda : IN STD_LOGIC_VECTOR (1 DOWNTO 0); -- Tomara valor 00 para senoidal, 01 para triangular y 10 para dientes de sierra
		amplitud : IN STD_LOGIC_VECTOR (1 DOWNTO 0);  -- Tomara valor 00 para 5 V, 01 para 2.5 V y 10 para 1.25
		frecuencia : IN STD_LOGIC_VECTOR (1 DOWNTO 0);-- Tomara valor 00 para 100 Hz, 01 para 200 y 10 para 500
	
		-- Convertidor D/A
		AB : OUT STD_LOGIC;							  -- Seleccion de canal
		D : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);		  -- Palabra digital
		CS : OUT STD_LOGIC;							  -- Activo en bajo
		WR : OUT STD_LOGIC;						 	  -- Activo en bajo, escritura de palabra digital
		CLR : OUT STD_LOGIC;						  -- Pone a 0 la palabra digital de ambos convertidores D/A, y la salida de ambos se pone a 0
		LDAC : OUT STD_LOGIC						  -- Con un flanco descendente ambos convertidores toman el valor de los registros
		
	);

END Generador_seniales;

-- Definimos la arquitectura
ARCHITECTURE arquitectura_Generador_seniales OF Generador_seniales IS

	SIGNAL valorFormaOnda : INTEGER RANGE 0 TO 255;					-- Posicion en la amplitud (tenemos 8 bits)
	SIGNAL valorFormaOndaSeno : STD_LOGIC_VECTOR (7 DOWNTO 0);  	-- Utilizado para obtener de la memoria el vector con el valor de la amplitud del seno
	SIGNAL frecuenciaMuestreo : STD_LOGIC;							-- Simula los pulsos de reloj segun la frecuencia seleccionada
	SIGNAL valorAmplitud : STD_LOGIC_VECTOR (7 DOWNTO 0);			-- Para el valor de la amplitud
	SIGNAL posicionMemoria : INTEGER RANGE 0 TO 255 :=0;			-- Para la posicion de memoria en el seno
	SIGNAL posicionMemoriaVector : STD_lOGIC_VECTOR (7 DOWNTO 0);	-- Conversion a vector de la posicion de memoria para la ROM instanciada
	
	-- Instanciamos la memoria del seno
	COMPONENT ROM_Seno
		PORT(
				address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				inclock		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
			);
	END COMPONENT;
	
	BEGIN
	
	-- Mapeo de la memoria del seno
	Memoria_Seno : ROM_Seno 
		PORT MAP (posicionMemoriaVector, 		-- Direccion de la memoria <= Address
				  frecuenciaMuestreo, 			-- Sincronizacion de acceso <= Inclock
				  valorFormaOndaSeno);			-- Salida de la memoria <= q
	
	-- Ponemos LDAC a 0 permanente y CLR a 1 permanente
	LDAC <= '0';
	CLR <= '1';
	
	-- Seleccionamos el DAC
	AB <= '0';
	
	-- Sincronizamos CS y WR con nuestra frecuencia de muestreo
	CS <= frecuenciaMuestreo;
	WR <= frecuenciaMuestreo;
	
	-- Escritura de la palabra digital
	D <= valorAmplitud;
	
	-- Proceso utilizado para obtener la posicion de la amplitud (valores desde 0 a 255), a los cuales ya le asignaremos
	-- posteriormente en valor en voltios segun la amplitud seleccionada, en funcion de la forma de onda seleccionada
	seleccionFormaOnda : PROCESS (formaOnda, frecuenciaMuestreo)
	
		VARIABLE subida : STD_LOGIC := '1';							-- Para marcar la subida y bajada en las seniales
		VARIABLE i : INTEGER RANGE 0 TO 255 := 0;					-- Para ir contando los 255 valores de amplitud (8 bits)	
		
		BEGIN
		
		  IF frecuenciaMuestreo'EVENT AND frecuenciaMuestreo = '1' THEN
		  
		    IF formaOnda = "00" THEN								-- Si hemos seleccionado seno
				
				posicionMemoria <= posicionMemoria + 1;				-- Aumentamos en 1 la posicion de la memoria a leer y la pasamos a vector
				posicionMemoriaVector <= conv_std_logic_vector(posicionMemoria,8);
				valorFormaOnda <= conv_integer(valorFormaOndaSeno); -- Guardamos el valor obtenido de la memoria convertido a entero
				
			END IF;
		
			IF formaOnda = "01" THEN								-- Si hemos seleccionado triangular
				
				IF subida = '1' THEN								-- Si subida esta activado
					IF i >= 255 THEN								-- Si hemos llegado a la maxima amplitud
						subida := '0';								-- Activamos el descenso
					ELSE
						i := i + 1;									-- En caso contrario, continuamos ascendiendo en amplitud
					END IF;
				ELSE												-- Si bajada esta activado
					IF i <= 0 THEN									-- Si hemos llegado a la minima amplitud
						subida := '1';								-- Activamos el ascenso
					ELSE
						i := i - 1;									-- En caso contrario, continuamos descendiendo en amplitud
					END IF;
				END IF;
				
				valorFormaOnda <= i;								-- Almacenamos el valor
		
			END IF;
			
			IF formaOnda = "10" THEN								-- Si hemos seleccionado triangular
					
				IF i = 255 THEN										-- Si hemos llegado a la maxima amplitud
					i := 0;											-- Bajamos al primer valor
				ELSE
					i := i + 1;										-- En caso contrario continuamos ascendiendo
				END IF;
				
				valorFormaOnda <= i;								-- Almacenamos el valor
				
			END IF;
		
		  END IF;
		
	END PROCESS;
	
	-- Proceso para obtener la amplitud segun el valor de la senial de seleccion de amplitud y el valor de la muestra en la forma de onda
	seleccionAmplitud : PROCESS (amplitud, valorFormaOnda)
	
		VARIABLE valor : STD_LOGIC_VECTOR (7 DOWNTO 0);
	
		BEGIN
		
			valor := conv_std_logic_vector (valorFormaOnda,8);		-- Nuestro valor almacenado de la posicion de amplitud lo pasamos a vector
	
		
			IF amplitud = "00" THEN				-- Amplitud de 5 V
				valorAmplitud <= valor (7 DOWNTO 0);
			END IF;
			
			IF amplitud = "01" THEN				-- Amplitud de 2.5 V
				valorAmplitud <= '0'&valor (7 DOWNTO 1);
			END IF;
			
			IF amplitud = "10" THEN				-- Amplitud de 1.25 V
				valorAmplitud <= "00"&valor (7 DOWNTO 2);
			END IF;
		
	END PROCESS;
	
	-- Proceso para obtener la frecuencia segun el valor de la senial de seleccion de frecuencia de salida
	seleccionFrecuencia : PROCESS (frecuencia)
	
		VARIABLE maximoPulsos : INTEGER RANGE 0 TO 300000;
		VARIABLE pulsos : INTEGER RANGE 0 TO 300000 := 0;
	
		BEGIN
		
			-- Seleccionamos el numero de pulsos necesario en nuestro reloj interno para que se produzca uno
			-- en nuestra frecuencia de salida seleccionada
			IF frecuencia = "00" THEN				-- Frecuencia de 100 Hz
				maximoPulsos := 492;
			END IF;
			
			IF frecuencia = "01" THEN				-- Frecuencia de 200 Hz
				maximoPulsos := 246;
			END IF;
			
			IF frecuencia = "10" THEN				-- Frecuencia de 500 Hz
				maximoPulsos := 98;
			END IF;
			
			-- Obtenemos la frecuencia de muestreo
			IF reloj'EVENT AND reloj = '1' THEN
				
				IF pulsos = maximoPulsos THEN
					frecuenciaMuestreo <= NOT frecuenciaMuestreo;
					pulsos := 0;
				ELSE
					pulsos := pulsos + 1;
				END IF;
				
			END IF;
			
	END PROCESS;
	

END arquitectura_Generador_seniales;