#ifndef PLATFORM_H
#define PLATFORM_H

#include <string>
#include <filesystem>
#include <fstream>

/* External Libs */
#define CPPHTTPLIB_MBEDTLS_SUPPORT
#include "external/httplib.h"
#include "external/json.hpp"

#pragma comment(lib, "bcrypt.lib")
namespace fs = std::filesystem;
using json = nlohmann::json;

class Platform 
{
public:
	Platform(std::string);

    /* API Handlers */
    int get_endpoint(std::string, json&);
    int post_endpoint(std::string, std::string, json&);

private: 
    httplib::Params oauth_params;
    std::string host;
	std::string token_endpoint;
	std::string access_token;

	/* Initializer Functions */
    int extract_credentials(std::string);
	int assign_value(std::string, std::string);
    int get_access_token();
};

Platform::Platform(std::string platform_name) 
/*
*   Constructor initializes platform credentials for API calls.
* 
*   Reads credentials in client_credentials.txt file and assigns member variables to key-value 
*   pairs associated with the provided platform name. Member variables are then formatted for 
*   an access token request. Which if successful, fully initializes the class for use in API calls.
*/
{
    if (extract_credentials(platform_name)) 
    {
	    std::cerr << "Failed to extract credentials for platform: '" << platform_name << "'" << std::endl;
        return;
    }

	if (get_access_token()) 
    {
        std::cerr << "Failed to get access token for platform: '" << platform_name << "'" << std::endl;
        return;
    }

	std::cout << "Successfully initialized platform: '" << platform_name << "'\n\n";    
    std::cout << "\tAccess Token: " << access_token << "\n" << std::endl;
}

int Platform::extract_credentials(std::string platform_name)
{
    /* simplify space stripping by enforcing name.key=value standard in .txt file */ /* not my problem if you can't follow the rules! */
    platform_name = platform_name + ".";
    fs::path file_path = fs::current_path() / "client_credentials.txt";

    std::ifstream file(file_path);
    if (file.is_open())
    {
        std::cout << "Extracting credentials for Platform: '" << platform_name << "'\n\n";
        
        std::string line;
        while (std::getline(file, line))
        {
			if (line.starts_with(platform_name))
            {
            
                std::string key_value = line.substr(platform_name.size());
                size_t delimiter_pos = key_value.find('=');

                if (delimiter_pos != std::string::npos)
                {
                    std::string key = key_value.substr(0, delimiter_pos);
                    std::string value = key_value.substr(delimiter_pos + 1);
                    value.erase(value.find_last_not_of(" \t") + 1);

                    if (assign_value(key, value))
                    {
                        std::cout << std::endl;
                        return -1;
                    }
                }
            }
        }

        file.close();

        std::cout << "\thost + token endpoint = '" << host << "' + '" << token_endpoint << "'\n" << std::endl;

        return 0;
    }
    else
    {
        std::cerr << "Could not open file: " << file_path << std::endl;
        return -1;
    }
}

int Platform::assign_value(std::string key, std::string value)
{
    if (key == "host") 
    {
		host = value;
    }
    else if (key == "token_endpoint")
    {
        token_endpoint = value;
    }
    else {
        std::cout << "\t'" << key << "' = '" << value << "'\n";
        oauth_params.emplace(key, value);
    }

    return 0;
}


int Platform::get_access_token()
/*  
*   Specialized request client for getting access token.
*
*   Uses extracted client credentials build a POST request.
*   This request is then sent to the provided endpoint to
*   get an access token.
*/
{
	if (host.empty() || token_endpoint.empty() || oauth_params.empty()) 
    {
        std::cerr << "Missing required credentials for access token request." << std::endl;
        return -1;
    }

    httplib::SSLClient cli(host, 443);
    cli.enable_server_certificate_verification(true);

    auto res = cli.Post(token_endpoint, oauth_params);

    if (res && res->status == 200) 
    {
		json response_json = json::parse(res->body);
		access_token = response_json["access_token"].get<std::string>();

		return 0;
    }
    else if (res) 
    {
		std::cerr << "HTTP Error: " << res->status << std::endl;
    }
    else 
    {
	    std::cerr << "HTTP Error: " << httplib::to_string(res.error()) << std::endl;
    }
    
    return -1;
}

int Platform::get_endpoint(std::string endpoint, json& response) 
{
    httplib::SSLClient cli(host, 443);
    
    std::string auth_header = "Bearer " + access_token;
    
    httplib::Headers headers = 
    {
       {"Authorization", auth_header},
       {"Content-Type", "application/json"}
    };

    auto res = cli.Get(endpoint, headers);

    if (!res || res->status != 200) 
    {
        std::cerr << "Request failed" << std::endl;
        return -1;
    }
        
    response = json::parse(res->body);

    return 0;
}

#endif // PLATFORM_H