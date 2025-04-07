//
//  Food.cpp
//  Meal Tracker
//
//  Created by Cem Beyenal on 10/3/23.
//

#include "Food.hpp"
using std::string;

Food::Food()
{
    mName = "";
    mGrams = 0;
    mCal = 0;
    mProtein = 0.0;
    mFat = 0.0;
    mCarb = 0.0;
    mServings = 0;
}

Food::~Food()
{
    
}

Food::Food(const Food &copy)
{
    mName = copy.mName;
    mGrams = copy.mGrams;
    mCal = copy.mCal;
    mProtein = copy.mProtein;
    mFat = copy.mFat;
    mCarb = copy.mCarb;
    mServings = copy.mServings;
}

string Food::getName()
{
    return mName;
}

int Food::getGrams()
{
    return mGrams;
}

int Food::getCal()
{
    return mCal;
}

double Food::getFat()
{
    return mFat;
}

double Food::getCarb()
{
    return mCarb;
}

double Food::getProtein()
{
    return mProtein;
}

int Food::getServings()
{
    return mServings;
}

void Food::setName(string newName)
{
    mName = newName;
}

void Food::setGrams(int newGram)
{
    mGrams = newGram;
}

void Food::setCal(int newCal)
{
    mCal = newCal;
}

void Food::setFat(double newFat)
{
    mFat = newFat;
}

void Food::setCarb(double newCarb)
{
    mCarb = newCarb;
}

void Food::setProtein(double newPro)
{
    mProtein = newPro;
}

void Food::setServings(int newServing)
{
    mServings = newServing;;
}


Food& Food::operator=( const Food &obj)
{
    if (this!= &obj)
    {
        // not the same object
        this->mCal = obj.mCal;
        this->mFat = obj.mFat;
        this->mCarb = obj.mCarb;
        this->mName = obj.mName;
        this->mProtein = obj.mProtein;
        this->mGrams = obj.mGrams;
        this->mServings = obj.mServings;
    }
    return *this;
}
