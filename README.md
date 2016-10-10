# income-map.FR
Use data from INSEE for representing the geographical distribution of income with R.

INSEE's geographical data on income are available under various forms:
* you can represent households' median income at the municipality level. The data are stored [here](http://www.insee.fr/fr/themes/detail.asp?reg_id=99&ref_id=indic-struct-distrib-revenu).
* you can also have access to 'squared' data, i.e. the French territory is divided into squares whose side is either 1 km long or 200 m long, and you are provided with information on population and average income inside each square. Depending on the density of population, anonymisation rules may be applied, leading to a fusion between squares. The data are available [here](http://www.insee.fr/fr/themes/detail.asp?reg_id=0&ref_id=donnees-carroyees).

This project also relies on IGN's data on administrative limits of the French territory, available [here](http://professionnels.ign.fr/geofla#tab-3).

The scripts developped here automatically downloads the data from the websites, unzipped them in the designated folder and allows to generate maps out of them.

Some snapshots of the GUI:

![snapshot1](https://github.com/pierre-lamarche/income-map.FR/blob/master/images/snapshot1.tiff)

![snapshot2](https://github.com/pierre-lamarche/income-map.FR/blob/master/images/snapshot2.tiff)

![snapshot3](https://github.com/pierre-lamarche/income-map.FR/blob/master/images/snapshot3.tiff)

![snapshot4](https://github.com/pierre-lamarche/income-map.FR/blob/master/images/snapshot4.tiff)

Under [EUP License](http://ec.europa.eu/idabc/eupl.html).