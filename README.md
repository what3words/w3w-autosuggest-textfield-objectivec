# <img valign='top' src="https://what3words.com/assets/images/w3w_square_red.png" width="64" height="64" alt="what3words">&nbsp;w3w-autosuggest-textfield-objective-c

A objective-c library to use What3words autosuggest

# Overview
The what3words Swift autosuggest is a simple UITextfield extension, which gives you access to, 

* All properties of UITextfield
* Dropdown autosuggest search results 
* Custom `IBInspectable` properties like Border Color, Width etc,.
* Custom `W3wSuggestion` properties like Country Clipping, number of results etc,.

This repository contains an Xcode project that builds a framework, and tests for the autosuggest component.  You may instead choose to skip the framework and simply drag and drop the `W3wGeocoder.h,  W3wGeocoder.m` & `W3wtextfield.h, W3wtextfield.m `files into your project.


# Installation

#### CocoaPods (iOS 8+, OS X 10.10+)

You can use [CocoaPods](http://cocoapods.org/) to install `w3w-objectivec-wrapper`by adding it to your `Podfile`:

```ruby
platform :ios, '10.0'
use_frameworks!

target 'MyApp' do
    pod 'W3wSuggestionField', :git => 'https://github.com/what3words/w3w-autosuggest-textfield-objectivec.git'
end
```

#### Manually

You can manually drag `W3wGeocoder.h,  W3wGeocoder.m` & `W3wtextfield.h, W3wtextfield.m ` into the project tree.  You can then skip the import statement in your code.

### Getting Started
Fire up Xcode and create a new `Single View App` project with `objective-c` as a language. Xcode will create your new objective-c project

### Step 1:

Add the following header to `viewcontroller.m` class:

```objectivec
#import <W3wTextField.h>
```

### Step 2:
Select `ViewController.m` and add the following code to the class:

```objective-c
@property (weak, nonatomic) IBOutlet W3wTextField *suggestionField;
```

Now, open Main.storyboard and drag a `UITextfield` to the screen from the Object library. In the Identity Inspector change the custom class to `W3wTextField`.The last thing to do is to connect the action to the button. Click the yellow View Controller icon in the View Controller scene. From the Connections Inspector (last tab on the right sidebar), click and drag the open circle next to `suggestionField ` to newly created `UITextfield` in the storyboard.

Initialize the API by placing the following code into the `viewDidLoad` method

```objective-c
[self.suggestionField setAPIKey:@"<Secret API Key>"];
```

#### Authentication

To use this library you’ll need a what3words API key, which can be signed up for [here](https://accounts.what3words.com/register?dev=true).


### Step 3:

To get selected three word address from dropdown menu, add the following code to the `ViewController.h` class

```objective-c
 [self.suggestionField didSelect:^(NSString *selectedText) {
    NSLog(@"Three word address: %@", selectedText);
  }];
```
### Customisation
There are a range of `W3wSuggestion` properties you can use to configure the autosuggest component.

| Variable      | Example           | Description  |
| :------------ |:-------------:| :-----|
| n-results<br><span style="color:#c7254e">Int</span>      | <span style="color:#c7254e">3</span> | number of results to return |
| autosuggest-focus<br><span style="color:#c7254e">String</span>       | <span style="color:#c7254e">51.521251,-0.203586</span>     |   comma separated lat/lng of point to focus on |
| n-focus-results<br><span style="color:#c7254e">Int</span>   | <span style="color:#c7254e">2</span>      |    the number of results within what is returned to apply the focus to |
| clip-to-country<br><span style="color:#c7254e">String</span>   | <span style="color:#c7254e">GB,US      |    confine results to a given country or comma separated list of countries |
| clip-to-bounding-box<br><span style="color:#c7254e">String</span>   | <span style="color:#c7254e">51.521,-0.343,52.6,2.3324</span>      |    Confine results to a bounding box specified using co-ordinates |
| clip-to-circle<br><span style="color:#c7254e">String</span>   | <span style="color:#c7254e">51.521,-0.343,142</span>      |    Restrict autosuggest results to a circle, specified by lat,lng,kilometres, where kilometres in the radius of the circle. For convenience, longitude is allowed to wrap around 180 degrees. For example 181 is equivalent to -179. |
| clip-to-polygon<br><span style="color:#c7254e">String</span>   | <span style="color:#c7254e">51.521,-0.343,52.6,2.3324,54.234,8.343,51.521,-0.343</span>    |    Restrict autosuggest results to a polygon, specified by a comma-separated list of lat,lng pairs. The polygon should be closed, i.e. the first element should be repeated as the last element; also the list should contain at least 4 entries. The API is currently limited to accepting up to 25 pairs. |
| debug<br><span style="color:#c7254e">Bool</span>   | <span style="color:#c7254e">false</span>      |    output information to console for debugging or throw error |

