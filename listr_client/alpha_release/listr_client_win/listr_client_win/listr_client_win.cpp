#include <iostream>
#include <string>
#include <cstdlib>

// static libs
#include "external/listr_client.hpp"

#define LOGIN 49
#define REGISTER 50
#define EXIT 51

int start_menu();

int main()
{
	
	int choice = start_menu();

	system("cls");
	std::cout << std::endl;

	Listr_Client listr_client;

    switch (choice)
    {
        case LOGIN:
            std::cout << "Login selected." << std::endl;

			if (listr_client.login() != 0)
			{
				return 1;
			}

			break;

        case REGISTER:
			std::cout << "Register selected." << std::endl;

			// TODO: Implement register function

			return 0;

        default:
            std::cout << "Exiting program." << std::endl;
			return 0;
    }
	
	system("cls");
	std::cout << "Geting user data...\n" << std::endl;

	listr_client.get_user();
}

int start_menu()
{   
    std::cout << "------------------------\nWelcome to Listr\n(rel a.1.0)"
        << "\n------------------------" << std::endl;

    std::string answer = "";

    while (1)
    {
        std::cout << "\n\nSelect from one of the following options to continue:\n" << std::endl;
        std::cout << "1. Login\n2. Register\n3. Exit\n" << std::endl;
        
        std::cin >> answer;

		if (answer[0] > '3' || answer[0] < '1')
        {
            std::cout << "Invalid input. Please try again." << std::endl;
            continue;
        }

        break;
    }

    return answer[0];
}