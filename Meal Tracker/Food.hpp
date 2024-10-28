//
//  Food.hpp
//  Meal Tracker
//
//  Created by Cem Beyenal on 10/3/23.
//

#ifndef Food_hpp
#define Food_hpp
#include <iostream>
#include <ostream>
#include <fstream>
#include <string>

using std::string;
using std::cout;
using std::ostream;

#include <stdio.h>


class Food
{
public:
    Food();
    ~Food();
    Food(const Food &copy);
    
    //write getters and setters here and add it to the run app load list function 10/8/23
    string getName();
    int getGrams();
    int getCal();
    double getFat();
    double getCarb();
    double getProtein();
    int getServings();
    
    void setName(string newName);
    void setGrams(int newGrams);
    void setCal(int newCal);
    void setFat(double newFat);
    void setCarb(double newCarb);
    void setProtein(double newPro);
    void setServings(int newServing);
    
    Food & operator=(const Food &obj);
    
    friend std::ostream& operator<<(std::ostream& os, const Food& obj) {
        os <<  obj.mName << std::endl
        << "Grams:" << obj.mGrams
        << "  Servings:" << obj.mServings
        << "  Calories:" << obj.mCal
        << "  Protein:" << obj.mProtein
        << "  Carbs:" << obj.mCarb
        << "  Fat:" << obj.mFat;
        return os;
    }
private:
    string mName;
    int mGrams;
    int mCal;
    double mFat;
    double mCarb;
    double mProtein;
    int mServings;
    
};

//ostream& operator<<(ostream& os, const Food &obj);
#endif /* Food_hpp */
