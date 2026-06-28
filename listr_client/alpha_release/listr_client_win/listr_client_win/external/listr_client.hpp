#ifndef LISTR_CLIENT_h
#define LISTR_CLIENT_H

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

const std::string listr_hostname = "listr.anticipateapi.com.au";

class Listr_Client
{
	public:
		int login();
		int get_user();

	private:
		std::string jwt_token;

		int get_token(std::string, std::string);
		int get_google();
};


int Listr_Client::login()
{
	std::cout << "------------------------\nListr	-	Login\n(rel a.1.0)"
		<< "\n------------------------\n" << std::endl;

	std::string email;
	std::string password;

	std::cout << "Enter Email: ";
	std::getline(std::cin, email);
	std::cout << "\n\nEnter Password: ";
	std::getline(std::cin, password);

	jwt_token = "";

	if (get_token(email, password) != 0)
	{
		std::cout << "Unable to reach server. Please try again later\n" << std::endl;
		return 1;
	}

	if (!jwt_token.empty())
	{
		std::cout << "\nLogin successful...\n" << std::endl;
		Sleep(3000);
	}
	else
	{
		std::cout << "\nUsername or Password not found. Please try again...\n" << std::endl;
		login();
	}

	return 0;
}

int Listr_Client::get_token(std::string email, std::string password)
{
	httplib::SSLClient cli(listr_hostname, 443);

	std::string body = R"({"email":")" + email + R"(","password":")" + password + R"("})";

	auto res = cli.Post("/auth/login", body, "application/json");

	if (!res || res->status != 200 && res->status != 401)
	{
		return 1;
	}

	if (res->status == 200)
	{
		json response_json = json::parse(res->body);
		jwt_token = response_json["token"].get<std::string>();
	}

	return 0;
}

int Listr_Client::get_user()
{
	std::cout << "Building header...\n";
	
	httplib::SSLClient cli(listr_hostname, 443);

	httplib::Headers headers =
	{
	   {"Authorization", "Bearer " + jwt_token},
	   {"Content-Type", "application/json"}
	};
	
	std::cout << "Calling get...\n";

	auto res = cli.Get("/users/me", headers);

	if (!res)
	{
		return 1;
	}

	if (res->status == 200)
	{
		json response_json = json::parse(res->body);
		std::cout << response_json.dump(4);
	}

	std::cout << "Response status and body:\n\n" << res->status << std::endl << res->body << std::endl;

	return 0;
}

int Listr_Client::get_google()
{

	httplib::SSLClient cli("www.google.com", 443);

	httplib::Headers headers =
	{
	   {"Content-Type", "application/json"}
	};

	auto res = cli.Get("/", headers);

	if (!res || res->status != 200)
	{
		std::cerr << "Request failed" << std::endl;
		return -1;
	}

	std::cout << res->body << std::endl;

	return 0;
}

#endif // LISTR_CLIENT_H