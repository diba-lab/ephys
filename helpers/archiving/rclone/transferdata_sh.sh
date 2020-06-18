
for name in {K,N}
	do
		for day in {1..4}
  			do 
				sleep 1d     				
				rclone copy --drive-server-side-across-configs myumichdrive:RawData/Rat$name/Day$day/ dibashared:Bapun/Rat$name/Day$day/
				

 			done
done


