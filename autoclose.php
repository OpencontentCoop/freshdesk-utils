<?php

#require __DIR__ . '/vendor/autoload.php';
#use \Freshdesk\Api;
#$dom='opencontent.freshdesk.com';
#$key='fIh7YsdPm03qAQpr5YBy';


//$api = new Api(getenv('FRESHDESK_API_KEY', getenv('FRESHDESK_DOMAIN')));
#$api = new Api($key, $dom);

#$all = $api->tickets->search('status:2');
#print_r($all);


$api_key = "fIh7YsdPm03qAQpr5YBy";
$password = "x";
$yourdomain = "opencontent.freshdesk.com";
$custom_fields = array(
#  "department" => "Production"
);


$url = "https://$yourdomain.freshdesk.com/api/v2/search/tickets?query=\"status:4\"";
$ch = curl_init($url);
$header[] = "Content-type: application/json";
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');
curl_setopt($ch, CURLOPT_HTTPHEADER, $header);
curl_setopt($ch, CURLOPT_HEADER, true);
curl_setopt($ch, CURLOPT_USERPWD, "$api_key:$password");
#curl_setopt($ch, CURLOPT_POSTFIELDS, $ticket_data);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$server_output = curl_exec($ch);
$info = curl_getinfo($ch);
print_r($info);
$header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
$headers = substr($server_output, 0, $header_size);
$response = substr($server_output, $header_size);
if($info['http_code'] == 200) {
  echo "Ticket updated successfully, the response is given below \n";
  echo "Response Headers are \n";
  echo $headers."\n";
  echo "Response Body \n";
  echo "$response \n";
} else {
  if($info['http_code'] == 404) {
    echo "Error, Please check the end point \n";
  } else {
    echo "Error, HTTP Status Code : " . $info['http_code'] . "\n";
    echo "Headers are ".$headers;
    echo "Response are ".$response;
  }
}
curl_close($ch);
