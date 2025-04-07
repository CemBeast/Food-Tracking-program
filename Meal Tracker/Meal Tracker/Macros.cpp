//
//  Macros.cpp
//  Meal Tracker
//
//  Created by Cem Beyenal on 3/25/25.
//

#include "Macros.hpp"

using std::string;

Macros::Macros()
{
    mCalories = 0;
    mProtein = 0.0;
    mCarbs = 0.0;
    mFats = 0.0;
}

Macros::~Macros()
{
    
}

Macros::Macros(const Macros &copy)
{
    mCalories = copy.mCalories;
    mProtein = copy.mProtein;
    mCarbs = copy.mCarbs;
    mFats = copy.mFats;
}

void Macros::setCalories(int newCal)
{
    mCalories = newCal;
}

void Macros::setProtein(double newProtein)
{
    mProtein = newProtein;
}

void Macros::setCarbs(double newCarbs)
{
    mCarbs = newCarbs;
}

void Macros::setFats(double newFats)
{
    mFats = newFats;
}

int Macros::getCalories() const
{
    return mCalories;
}

double  Macros::getProteins() const
{
    return mProtein;;
}

double  Macros::getCarbs() const
{
    return mCarbs;
}

double  Macros::getFats() const
{
    return mFats;
}
