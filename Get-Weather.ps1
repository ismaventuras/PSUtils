
function Get-Weather {
    <#
        .SYNOPSIS
            Get the current weather using the city name.
        .DESCRIPTION
            Use an API from https://openweathermap.org/ to get the weather from a specific City. 
        .PARAMETER City
            Specifies the name of the city
        .PARAMETER API_Key
            Specifies the api_key from https://openweathermap.org
        .PARAMETER Lang
            Specifies the lang in a 2 digit code
        .PARAMETER Units
            Specifies the unit that temperature will use, imperial for Fahrenheit, metric for Celsius
        .EXAMPLE
            PS C:\> Get-Weather -City "Barcelona" -CountryCode "es"
            The command receives a string with the City and the country code and outputs an object including weather's info
        .EXAMPLE
            PS C:\> Get-Weather "Barcelona"
            The command receives a string with the City and outputs an object including weather's info, it takes the first City on that the API finds with that name.
        .INPUTS
            None. You cannot pipe objects to Get-Weather
        .OUTPUTS
           PSCustomObject. Get-Weather returns an object with the city's weather information.
        .NOTES
            General notes
        .LINK
            https://openweathermap.org

    #>
    [CmdletBinding()]
    param(
        [string] $City ,
        [string] $CountryCode ,
        [string] $API_Key = "e9b28b35d0650c6cf93f45ead5c29ec6" ,
        [string] $Lang = "en" ,
        [string] $Units = "metric"
    )
     #Si el usuario no ha introducido ninguna ciudad, para la función
     #If there's no city, stop the function
     if(!$City){
         Write-Output 'No city specified, please remember to add City,CountryCode'
         return
     }
    #Usamos la API de openweathermap para obtener los datos meteorologicos de la ciudad de Barcelona, en caso de error imprimelo y para la función
    #Using openweathermap API to get the weather data using a REST method, in case of error print it and stop the function
    try {
        $Weather_JSON = Invoke-RestMethod -Uri "api.openweathermap.org/data/2.5/weather?q=${City},${CountryCode}&APPID=${API_KEY}&lang=${Lang}&units=${Units}" -ErrorVariable error
    }
    catch  {
        Write-Output $error
        return
    }
     
    #Creamos un objeto para guardar los datos que necesitamos de la consulta y lo devolvemos
    #Creating and object where the data is saved and return the object
    return [PSCustomObject]@{
        city            = $Weather_JSON.name
        temperature     = "$($Weather_JSON.main.temp)"
        humidity        = $Weather_JSON.main.humidity
        max_temperature = "$($Weather_JSON.main.temp_max)"
        min_temperature = "$($Weather_JSON.main.temp_min)"
        description     = $Weather_JSON.weather.description
        wind_speed      = $Weather_JSON.wind.speed
        clouds          = "$($Weather_JSON.clouds.all)%"
    } 
    
}