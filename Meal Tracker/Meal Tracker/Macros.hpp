//
//  Macros.hpp
//  Meal Tracker
//
//  Created by Cem Beyenal on 3/25/25.
//

#ifndef Macros_hpp
#define Macros_hpp
#include <iostream>
#include <ostream>
#include <fstream>
#include <string>
#include <stdio.h>


using std::string;
using std::cout;
using std::ostream;


class Macros
{
    public:
        Macros();
        ~Macros();
        Macros(const Macros &copy);

        void setCalories(int newCal);
        void setProtein(double newProtein);
        void setCarbs(double newCarbs);
        void setFats(double newFats);
        
        int getCalories() const;
        double getProteins() const;
        double getCarbs() const;
        double getFats() const;
    
        Macros &operator=( const Macros &obj);
    
        friend std::ostream& operator<<(std::ostream& os, const Macros& obj) {
            os << "  Calories:" << obj.mCalories
            << "  Protein:" << obj.mProtein
            << "  Carbs:" << obj.mCarbs
            << "  Fat:" << obj.mFats;
            return os;
        }
        
    private:
        int mCalories;
        double mProtein;
        double mCarbs;
        double mFats;
};
#endif
