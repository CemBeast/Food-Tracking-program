//
//  RunApp.hpp
//  Meal Tracker
//
//  Created by Cem Beyenal on 10/3/23.
//  instead of using arrays we need to implement a vector so that it can vary in size


#ifndef RunApp_hpp
#define RunApp_hpp

#include "Food.hpp"
#include "Macros.hpp"
#include <vector>
#include <cctype>
#include <ctime>
#include <sstream>

using namespace std;


class RunApp
{
public:
    RunApp();
    ~RunApp();
    
    void RunGame();
    int readFile();
    void loadList();
    void loadDailyMacros();
    void printDictionary();
    Food calculateFoodMacros();
    void printMenu();
    int getChoice();
    void printMacrosList(); // print macros for each food  from calculated servings
    void printTotalMacros();
    void addFoodToDictionary();
    void addFoodToDictionary(string name);
    void saveDictionary();
    void writeToLog();
    void writeToDailyLog();
    void editFood();
    void QuickFood();
    void printFoodAteInSession();
    void printTotalFoodAteInSession();
    bool isToday();
    bool isTodayForDayFoods();
    void writeToDatesAndMacrosFile();
    void printDatesAndMacros();
    void readDatesAndMacrosFile();
    void printAverages();
private:
    vector<Food> mList; // register of all food items -- food dictionary read from FoodData and loaded in
    vector<Food> mLog; // log- each meal logged on it and then printed to the FoodLog File
    vector<Food> mDailyLog; // loads the food ate today into this vector for printing daily macros
    vector<pair<string, string> > mDatesAndMacros;
    fstream mfoodFile;
    fstream mFoodLog; // only is written to appending good ate
    fstream DayTotals;
    fstream mFoodAteTodayFile;
    fstream mMacrosLog;
    int mFoodNum;
    Macros dailyMacros;
    
};

string toLowerCase(const string& input) {
    string result;
    for (char ch : input) {
        result += std::tolower(static_cast<unsigned char>(ch));
    }
    return result;
}

RunApp::RunApp ()
{
    mFoodNum = 0;
}

RunApp::~RunApp ()
{
    
}

void RunApp::RunGame()
{
    int choice = 0;
    
    
    writeToDatesAndMacrosFile();
    readDatesAndMacrosFile();
    mFoodNum = readFile();
    Food foodEntry;
    do
    {
        loadDailyMacros();
        printMenu();
        choice = getChoice();
        switch (choice){
            case 1:  foodEntry = calculateFoodMacros();
                mLog.push_back(foodEntry);
                break;
            case 2: printMacrosList();
                break;
            case 3: printTotalMacros();
                break;
            case 4: addFoodToDictionary();
                break;
            case 5: printDictionary();
                break;
            case 6: saveDictionary();
                break;
            case 7: writeToLog();
                break;
            case 8: editFood();
                break;
            case 9: QuickFood();
                break;
            case 10: printFoodAteInSession();
                break;
            case 11: printTotalFoodAteInSession();
                break;
            case 12: printDatesAndMacros();
                break;
        }
    }while (choice != 13);
    saveDictionary();
}

void RunApp::printMenu()
{
    cout << "---------------------------------------------------------" << endl;
    cout << dailyMacros << endl;
    cout << "---------------------------------------------------------" << endl;
    cout << "1. Enter food item" << endl;
    cout << "2. Print list of food ate today with macros" << endl;
    cout << "3. Print total macros" << endl;
    cout << "4. Add food to dictionary" << endl;
    cout << "5. Print food dictionary" << endl;
    cout << "6. Save Dictionary file" << endl;
    cout << "7. Write food to log file" << endl;
    cout << "8. Edit Food" << endl;
    cout << "9. Enter quick food" << endl;
    cout << "10. Print food ate in this session" << endl;
    cout << "11. Print total macros of food ate in this session" << endl;
    cout << "12. Print log of macros for each day" << endl;
    cout << "13. Exit" << endl;
    cout << "---------------------------------------------------------" << endl;
}



int RunApp::getChoice()
{
    int choice = 0;
    while(true){
    cin >> choice;
        if (std::cin.fail()) {
            // If not, clear the error state
            std::cin.clear();
            
            // Ignore the rest of the invalid input
            std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
            
            // Inform the user of the invalid input
            std::cout << "Invalid input. Please enter a valid number." << std::endl;
        }
        else
            break;
        }
    return choice;
}

// Reads the food fils to load it into an array
int RunApp::readFile()
{
    int i = 0, calories = 0, grams = 0, servings = 0;
    string name = "", strName = "", strPro = "", strCal = "", strCarb = "", strFat = "", strGrams = "", strServings = "";
    double protein = 0.0, carbs = 0.0, fat = 0.0;
    Food temp;
    mfoodFile.open("FoodData.csv");
    if(!mfoodFile.is_open())
    {
        cout << "error Opening file" << endl;
        return 0;
    }
    
    while (true)
    {
        getline(mfoodFile, name, ',');
        getline(mfoodFile, strGrams, ',');
        grams = stoi(strGrams);
        getline(mfoodFile, strServings, ',');
        servings = stoi(strServings);
        getline(mfoodFile, strCal, ',');
        calories = stoi(strCal);
        getline(mfoodFile, strPro, ',');
        protein = stof(strPro);
        getline(mfoodFile, strCarb, ',');
        carbs = stof(strCarb);
        getline(mfoodFile, strFat, '\n');
        fat = stof(strFat);
        temp.setCal(calories);
        temp.setFat(fat);
        temp.setProtein(protein);
        temp.setName(name);
        temp.setCarb(carbs);
        temp.setGrams(grams);
        temp.setServings(servings);
        if(mfoodFile.eof())
            break;
        mList.push_back(temp);
        i++;
    }
    mfoodFile.close();
    return i;
}

bool compareByName(Food &a, Food &b)
{
    return a.getName() < b.getName();
}

bool compareByCalories(Food& a, Food& b)
{
    return a.getCal() < b.getCal();
}

bool compareByProtein(Food& a, Food& b)
{
    return a.getProtein() < b.getProtein();
}

bool compareByCarbs(Food& a, Food& b)
{
    return a.getCarb() < b.getCarb();
}

bool compareByFats(Food& a, Food& b)
{
    return a.getFat() < b.getFat();
}

// prints the food dictionary
void RunApp::printDictionary()
{
    cout << "1. Sort by name" << endl;
    cout << "2. Sort by calories" << endl;
    cout << "3. Sort by protein" << endl;
    cout << "4. Sort by carbs" << endl;
    cout << "5. Sort by fats" << endl;
    int choice = 0;
    cin >> choice;
    switch (choice)
    {
        case 1:
            std::sort(mList.begin(), mList.end(), compareByName);
            break;
        case 2:
            std::sort(mList.begin(), mList.end(), compareByCalories);
            break;
        case 3:
            std::sort(mList.begin(), mList.end(), compareByProtein);
            break;
        case 4:
            std::sort(mList.begin(), mList.end(), compareByCarbs);
            break;
        case 5:
            std::sort(mList.begin(), mList.end(), compareByFats);
            break;
        default:
            cout << "Invalid choice, pritning unsorted" << endl;
    }
    
    for(auto i = mList.begin(); i != mList.end(); ++i)
    {
        cout << *i << endl;
        cout << endl;
    }
}

void RunApp::saveDictionary()
{
    mfoodFile.open("FoodData.csv");
    for(auto i = mList.begin(); i != mList.end(); ++i)
    {
        mfoodFile << i->getName() << "," << i->getGrams() << ","  << i->getServings() <<  "," << i->getCal() << "," << i->getProtein() << ","<< i->getCarb() << "," << i->getFat() << endl;
    }
    mfoodFile.close();
}

Food RunApp::calculateFoodMacros()
{
    string finish = "", foodName = "";
    double quantity = 0.0, ratio = 0.0, servings = 0;
    int k = 0;
    bool valid = false;
    char choice2;
    Food Macros;
    do
    {
        cout << "What is the name of the food you wish to log?" << endl;
        cin.ignore();
        getline(cin, foodName);
        
        k = 0;
        for(auto i = mList.begin(); i != mList.end(); ++i)
        {
            if (toLowerCase(i->getName()) == toLowerCase(foodName))
            {
                valid = true;
                break;
            }
            k++;
        }
        
        if(!valid)
        {
            cout << "The food you entered is not in the registry" << endl;
            cout << "Would you like to enter this food in the register? Y or N" << endl;
            cin >> choice2;
            if (choice2 == 'Y' || choice2 == 'y')
            {
                addFoodToDictionary(foodName);
                break;
            }
            else
            {
                cout << "Enter a food in the dictionary" << endl;
            }
            
        }
    }while (!valid);
    
   
    // now calculate the macros of that food.
    if (mList[k].getGrams() == 0)
    {
        //it is a servings
        cout << "How many servings did you have?" << endl;
        cin >> servings;
        ratio = servings /(double) mList[k].getServings();

    }
    else
    {
        // it is weighable
        cout << "How many grams of it did you eat?" << endl;
        cin >> quantity;
        ratio = quantity /(double) mList[k].getGrams();
    }
    Macros.setCal(ratio * (double)mList[k].getCal());
    Macros.setFat(ratio * mList[k].getFat());
    Macros.setProtein(ratio * mList[k].getProtein());
    Macros.setCarb(ratio * mList[k].getCarb());
    Macros.setGrams(quantity);
    Macros.setName(mList[k].getName());
    Macros.setServings(servings);
    return Macros;
}

void RunApp::printFoodAteInSession()
{
    /// Used to print food ate only during that session as data was saved temporarily
    for(auto i = mLog.begin(); i != mLog.end(); ++i)
    {
        cout << *i << endl;
    }
}

void RunApp::printMacrosList() // print macros from calculated servings
{
    string line = "";

    cout << "Food ate today:" << endl;
    
    mFoodAteTodayFile.open("DayFoods.txt");
    getline(mFoodAteTodayFile, line);
    while(true)
    {
        getline(mFoodAteTodayFile, line);
        cout << line << endl;
        if(mFoodAteTodayFile.eof())
            break;
    }
    mFoodAteTodayFile.close();
    
}

void RunApp::printTotalFoodAteInSession()
{
    // Used to print food ate only during that session as data was saved temporarily
    int totalCal = 0;
    double totalPro = 0.0, totalCarb = 0.0, totalFat = 0.0;
    for(auto i = mLog.begin(); i != mLog.end(); ++i)
    {
        totalCal += i->getCal();
        totalPro += i->getProtein();
        totalCarb += i->getCarb();
        totalFat += i->getFat();
    }
    cout << "Calories:" << totalCal << "  Protein:" << round(totalPro) << "  Carbs:" << round(totalCarb) << "  Fats:" << round(totalFat) << endl;
 
}

void RunApp::printTotalMacros()
{
   if(isToday())
    {
        cout << "Calories:" << round(dailyMacros.getCalories()) << "  Protein:" << round(dailyMacros.getProteins()) << "  Carbs:" << round(dailyMacros.getCarbs()) << "  Fats:" << round(dailyMacros.getFats()) << endl;
    }
    else
    {
        cout << "Calories:0 Protein:0 Carbs:0 Fats:0" << endl;
    }
}

void RunApp::addFoodToDictionary()
{
    Food newFood;
    string name = "";
    int cals = 0, grams = 0, servings = 0;
    double protein = 0.0, carbs = 0.0, fats = 0.0;
    bool weighOrServing = false;
    cout << "Enter the food name: ";
    cin.ignore();
    getline(cin, name);
    cout << "Is your food meadured by weight(1) or is your food measured by servings(0):";
    cin >> weighOrServing;
    if (weighOrServing)
    {
        cout << "Enter the serving size in grams: ";
        cin >> grams;
    }
    else{
        cout << "Enter the amount of servings: ";
        cin >> servings;
    }
    cout << "Enter how many calories are in one serving: ";
    cin >> cals;
    cout << "Enter how much protein is in one serving: ";
    cin >> protein;
    cout << "Enter how many carbs are in one serving: ";
    cin >> carbs;
    cout << "Enter how many fats are in one serving: ";
    cin >> fats;
    newFood.setCal(cals);
    newFood.setFat(fats);
    newFood.setProtein(protein);
    newFood.setCarb(carbs);
    newFood.setName(name);
    newFood.setGrams(grams);
    newFood.setServings(servings);
    mList.push_back(newFood);
}

void RunApp::addFoodToDictionary(string name)
{
    Food newFood;
    int cals = 0, grams = 0, servings = 0;
    double protein = 0.0, carbs = 0.0, fats = 0.0;
    bool weighOrServing = false;
    cout << "Is your food meadured by weight(1) or is your food measured by servings(0):";
    cin >> weighOrServing;
    if (weighOrServing)
    {
        cout << "Enter the serving size in grams: ";
        cin >> grams;
    }
    else{
        cout << "Enter the amount of servings: ";
        cin >> servings;
    }
    cout << "Enter how many calories are in one serving: ";
    cin >> cals;
    cout << "Enter how much protein is in one serving: ";
    cin >> protein;
    cout << "Enter how many carbs are in one serving: ";
    cin >> carbs;
    cout << "Enter how many fats are in one serving: ";
    cin >> fats;
    newFood.setCal(cals);
    newFood.setFat(fats);
    newFood.setProtein(protein);
    newFood.setCarb(carbs);
    newFood.setName(name);
    newFood.setGrams(grams);
    newFood.setServings(servings);
    mList.push_back(newFood);
}

void RunApp::writeToLog()
{
    time_t now = time(0);
    char *dt = ctime(&now);
    int totalCal = 0, count = 0;
    double totalPro = 0.0, totalCarb = 0.0, totalFat = 0.0;
    string line = "", date = "", junk = "", proteinStr = "", carbStr = "", calorieStr = "", fatStr = "";
    
    DayTotals.open("DayTotals.txt");
    if(!DayTotals.is_open())
    {
        cout << "error Opening file" << endl;
    }
    // read DayTotals file to see if it is the same day, if it is, we add to the totals that we already have
    while (true)
    {
        getline(DayTotals, junk, '-');
        getline(DayTotals, date, '\n');
        getline(DayTotals, junk, ':');
        getline(DayTotals, calorieStr, ' ');
        getline(DayTotals, junk, ':');
        getline(DayTotals, proteinStr, ' ');
        getline(DayTotals, junk, ':');
        getline(DayTotals, carbStr, ' ');
        getline(DayTotals, junk, ':');
        getline(DayTotals, fatStr, '\n');
        if(DayTotals.eof())
            break;
    }
    // Checks for the first 10 char in day file and if todays date variable are the same - meaning that the days are the same, we increment count for each character are the same
    for(int j = 0; j < 10; j++)
    {
        if(dt[j] == date[j])
        {
            count++;
        }
    }
    // if the strings first 10 characters are the same then we increment the day total with the food logs total
    if (count == 10)
    {
        totalCal += stoi(calorieStr);
        totalPro += stoi(proteinStr);
        totalCarb += stoi(carbStr);
        totalFat += stoi(fatStr);
    }
    DayTotals.close();

    
    // Prints to the food file for user to read
    mFoodLog.open("FoodLog.txt", std::ios::app);
    mFoodLog << "Date: " << dt;
    for(auto i = mLog.begin(); i != mLog.end(); ++i)
    {
        mFoodLog << *i << endl;
        totalCal += i->getCal();
        totalPro += i->getProtein();
        totalCarb += i->getCarb();
        totalFat += i->getFat();
    }
    mFoodLog << "Todays Totals:" << endl << "Calories:" << totalCal << "  Protein:" << round(totalPro) << "  Carbs:" << round(totalCarb) << "  Fats:" << round(totalFat) << endl;
    mFoodLog << "----------------------------------------------------------------------------------" << endl;
    mFoodLog.close();
    
    
    // Prints the days total and the date
    DayTotals.open("DayTotals.txt");
    DayTotals << "Date-" << dt;
    DayTotals <<  "Calories:" << totalCal << "  Protein:" << round(totalPro) << "  Carbs:" << round(totalCarb) << "  Fats:" << round(totalFat) << endl;
    DayTotals.close();
    
    writeToDailyLog();

}

void RunApp::QuickFood()
{
    int cals = 0;
    double protein = 0.0, carbs = 0.0, fats = 0.0;
    string foodName = "";
    Food food;
    cout << "What is the name of the food?";
    cin.ignore();
    getline(cin, foodName);
    cout << "How many calories is it?";
    cin >> cals;
    cout << "How many grams of protein are in it?";
    cin >> protein;
    cout << "How many grams of carbs are in it?";
    cin >> carbs;
    cout << "How many grams of fats are in it?";
    cin >> fats;
    food.setCal(cals);
    food.setProtein(protein);
    food.setFat(fats);
    food.setName(foodName);
    food.setCarb(carbs);
    mLog.push_back(food);
}

void RunApp::editFood()
{
    string name = "", newName = "";
    int newWeight = 0, newServings = 0, newCal = 0, choice = 0;
    double newProtein = 0.0, newCarbs = 0.0, newFats = 0.0;
    std::vector<Food>::iterator location;
    cout << "Enter the name of the food you wish to edit: ";
    cin.ignore();
    getline(cin, name);
    for(auto i = mList.begin(); i != mList.end(); ++i)
    {
        if(toLowerCase(i->getName()) == toLowerCase(name)) // need to make sure it is not case sensitive WORK ON THIS FIRST
        {
            do
            {
                cout << "What do you wish to edit?" << endl;
                cout << "1) Name" << endl << "2) Weight" << endl << "3) Servings" << endl << "4) Calories" << endl << "5) Protein" << endl << "6) Carbohydrates" << endl << "7) Fats" << endl << "8) Finished Edititing" << endl;
                choice = getChoice();
                switch (choice){
                    case 1: cout << "Enter the new name:";
                            cin >> newName;
                        i->setName(newName);
                        break;
                    case 2: cout << "Enter the new weight in grams:";
                            cin >> newWeight;
                        i->setGrams(newWeight);
                        break;
                    case 3: cout << "Enter the new servings:";
                            cin >> newServings;
                        i->setServings(newServings);
                        break;
                    case 4: cout << "Enter the new calories: ";
                            cin >> newCal;
                        i->setCal(newCal);
                        break;
                    case 5: cout << "Enter the new protein:";
                            cin >> newProtein;
                        i->setProtein(newProtein);
                        break;
                    case 6: cout << "Enter the new carbohydrates:";
                            cin >> newCarbs;
                        i->setCarb(newCarbs);
                        break;
                    case 7: cout << "Enter the new fats: ";
                            cin >> newFats;
                        i->setFat(newFats);
                        break;
                }
            }while(choice != 8);
        }
    }
    
}

void RunApp::loadDailyMacros()
{
    if( isToday())
    {
        string txt = "", junk = "", proteinStr = "", carbStr = "", calorieStr = "", fatStr = "";
        DayTotals.open("DayTotals.txt");
        getline(DayTotals, txt, '\n');
        getline(DayTotals, junk, ':');
        getline(DayTotals, calorieStr, ' ');
        getline(DayTotals, junk, ':');
        getline(DayTotals, proteinStr, ' ');
        getline(DayTotals, junk, ':');
        getline(DayTotals, carbStr, ' ');
        getline(DayTotals, junk, ':');
        getline(DayTotals, fatStr, '\n');
        DayTotals.close();
        
        dailyMacros.setCalories(stoi(calorieStr));
        dailyMacros.setProtein(stoi(proteinStr));
        dailyMacros.setCarbs(stoi(carbStr));
        dailyMacros.setFats(stoi(fatStr));
    }
    else
    {
        dailyMacros.setCalories(0);
        dailyMacros.setProtein(0.0);
        dailyMacros.setCarbs(0.0);
        dailyMacros.setFats(0.0);
    }
}

void RunApp::writeToDailyLog()
{
    ///implement way to read the file and check if its the same day, if it is then we append, otherwise we write over.
    ///make the function isToday() to check if its today llmao
    
    time_t now = time(0);
    char *dt = ctime(&now);
    string junk = "", date = "";
    
    if (!isTodayForDayFoods())
    {
        // rewrite
        mFoodAteTodayFile.open("DayFoods.txt", std::ofstream::out | std::ofstream::trunc);
        mFoodAteTodayFile << "Date-" << dt;
        mFoodAteTodayFile << "---------------------------------------------------------" << endl;
        for(auto i = mLog.begin(); i != mLog.end(); ++i)
        {
            mFoodAteTodayFile << *i << endl;
        }
        mFoodAteTodayFile.close();
    }
    else
    {
        // appends to the file
        mFoodAteTodayFile.open("DayFoods.txt", std::ios::app);
        for(auto i = mLog.begin(); i != mLog.end(); ++i)
        {
            mFoodAteTodayFile << *i << endl;
        }
        mFoodAteTodayFile.close();
    }
}

bool RunApp::isToday()
{
    time_t now = time(0);
    char *dt = ctime(&now);
    string junk = "", date = "";
    int count = 0;
    bool ans = false;
    
    // get date
    DayTotals.open("DayTotals.txt");
    
    getline(DayTotals, junk, '-');
    getline(DayTotals, date, '\n');
    // Checks for the first 10 char in day file and if todays date variable are the same - meaning that the days are the same, we increment count for each character are the same
    for(int j = 0; j < 10; j++)
    {
        if(dt[j] == date[j])
        {
            count++;
        }
        else
            break;
    }
    if(count == 10)
    {
        ans = true;
    }
    DayTotals.close();
    
    return ans;

}

bool RunApp::isTodayForDayFoods()
{
    time_t now = time(0);
    char *dt = ctime(&now);
    string junk = "", date = "";
    int count = 0;
    bool ans = false;
    
    // get date
    DayTotals.open("DayFoods.txt");
    
    getline(DayTotals, junk, '-');
    getline(DayTotals, date, '\n');
    // Checks for the first 10 char in day file and if todays date variable are the same - meaning that the days are the same, we increment count for each character are the same
    for(int j = 0; j < 10; j++)
    {
        if(dt[j] == date[j])
        {
            count++;
        }
    }
    if(count == 10)
    {
        ans = true;
    }
    DayTotals.close();
    
    return ans;

}

// writes to the history log
void RunApp::writeToDatesAndMacrosFile()
{
    if (!isToday())
    {
        string date = "", macros = "";

        DayTotals.open("DayTotals.txt");
        getline(DayTotals, date);
        getline(DayTotals, macros);
        DayTotals.close();
        
        mMacrosLog.open("MacrosLog.txt", std::ios::app); // make it append
        mMacrosLog << date << endl;
        mMacrosLog << macros << endl;
        mMacrosLog.close();
    }
}

// writes to the history log
void RunApp::readDatesAndMacrosFile()
{
    string date = "", macros = "";
    
    mMacrosLog.open("MacrosLog.txt");
    
    while (std::getline(mMacrosLog, date) && std::getline(mMacrosLog, macros)) {
        mDatesAndMacros.emplace_back(date, macros);
    }
    mMacrosLog.close();

}



void RunApp::printDatesAndMacros()
{
    for(const auto &pair : mDatesAndMacros)
    {
        cout << pair.first << endl;
        cout << pair.second << endl;
    }
}

void RunApp::printAverages()
{
    
    double avgCal = 0.0, avgProtein = 0.0, avgCarb = 0.0, avgFat = 0.0;
    
    
    cout << "1. Average calories" << endl;
    cout << "2. Average protein" << endl;
    cout << "3. Average carbs" << endl;
    cout << "4. Average fats" << endl;
    int choice = 0;
    cin >> choice;
    
    
    switch (choice)
    {
        case 1:
            std::sort(mList.begin(), mList.end(), compareByName);
            break;
        case 2:
            std::sort(mList.begin(), mList.end(), compareByCalories);
            break;
        case 3:
            std::sort(mList.begin(), mList.end(), compareByProtein);
            break;
        case 4:
            std::sort(mList.begin(), mList.end(), compareByCarbs);
            break;
        case 5:
            std::sort(mList.begin(), mList.end(), compareByFats);
            break;
        default:
            cout << "Invalid choice, pritning unsorted" << endl;
    }}


#endif /* RunApp_hpp */
