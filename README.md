# ABNLocations

This is an iOS native project developed with Xcode 16 and Swift 6. The project requires a minimum iOS version of 17. It does not use CocoaPods for dependency management; instead, it relies on custom-made Swift packages that are nested within the project folder.

This document starts with a technical description of the project, and will carry on with a rationale about how it was built, and why. Finally, it will briefly explain te modifications made to the Wikipedia app.

The counterpart Wikipedia app can be found here: [Wikipedia](https://github.com/joris1995/wikipedia-ios-places-mod/settings)
I intended to just commit on a custom fork, but my git client acted up when I tried to commit this and it's late, so I created a separate repo.

## Requirements

- **Xcode**: 16 or later
- **Swift**: 6.0 or later
- **iOS Version**: 17.0 or later
- **Dependencies**: No CocoaPods required

This app uses SwiftData and Typed Throws, which are recently added features.

## Architecture
The project follows the Clean Architecture as represented in the following picture:
![Architecute overview](https://miro.medium.com/v2/resize:fit:4800/format:webp/1*be0csos3sWD9I5KhFz_8dg@2x.jpeg)

Each layer in this architecture is represented by it's own Swift Package. The exception made from the image is that Usecases do not hold their own models, but use models that are available throughout the application.

## Project Structure

The project is organized with modular Swift packages, each located within the main project folder. Each package represents a different 'Layer' of the application, starting at the all the way at the 'bottom' with a package containing models and types, and layering all the way up to the ui in the 'Presentation' package. Each package contains its relevant sources and logic tests.

### Package Structure
1. Domain: Project wide code. Models, in this case
2. Service: The layer that interacts with local and remote services to perform data logistics on the models in the app.
3. Repository: The mediation later between app usecase logic and data.
4. UseCase: Singular logic components that are used throughout the application
5. Presentation: The UI and belonging logic (ViewModels). This layer also contains relevant logic for generating classes that are needed throughout the UI lifecycle.

### App flow
These packages are imported in the main application, starting at `ABNLocationsApp.swift`. This is the entry point of the app, and contains two parts: The main app view, and factories that inject dependencies needed into it.

# Rationale

## Intro
This project was built as an assignment for ABN Amro Bank. It consists of two parts; this application and a modified version of the Wikipedia app, to be found here: [Wikipedia](https://github.com/joris1995/wikipedia-ios-places-mod/settings).

As per the assignment, the app loads and displays a set of locations from an endpoint. Upon selecting a location, the user can trigger that location in the modified Wikipedia app's Places tab.
Additionally, users can add their own locations and trigger those in the wikipedia app, provided valid coordinates are present.

In addition to the requirements of the assigment, some other things are present in this app:

1. A mechanism that stores all data into local persistence (using SwiftData), acting as a 'Single Source of Truth'. After an initial load, the user can access locations loaded from the server later when there is no connection too. Each record is given an expirationDate, after which server records are deleted.
2. A mechanism that provides suggestions to users when adding custom locations, helping them to more smoothly determine the coordinates of their location. This uses Mapkit, and is a simple, minimal autocomplete service.
3. A mechanism that allows users to modify and delete custom locations, but not the locations from the server, since they will always be the same with our current limited back-end.


## Scope
When coming out of my first interview with ABN Amro, I didn't feel I succeeded in bringing across my expertise when it comes to architecture of applications. This bugged me, and therefore I chose to try and compensate this with this project. I want to display:

1. My capabilities around clean project architecture, modularity, and testability
2. The way I set up a project structure to start small and be able to scale large, using a composition of packages that is as compiler efficient as possible
3. My awareness of recent swift features such as SwiftData, typed throws, Concurrency (Actors) and asynchronousity
4. My way around tests
5. Error handling

There are also some things that I purpously left out of scope for this project:

1. Design. I am proficient in translating designs into custom UI's. As a reference, I'd like to point to my own app, Dart Scores. This is fully custom. Leaving this component out in this project allowed me to focus more on the things I wanted to express.
2. Development/Staging Targets & configurations: Mocks are injected into repositories during tests, but I chose not to create an extra app target.
3. Extensive localization: I implemented localization for english, but since the back-end does not support any other languages yet, i chose to limit myself to one language. This saves us a lot of work when we want to expand to other countries.
4. UI Tests & Mocked viewmodels; When it comes to ViewModels, I deflect from the SOLID principles by depending on implementations, but I do this because there are no UI tests in place in the current setup.
5. Advanced networking configuration was not relevant for this project. I set up a basic, custom configuration object but as the project grows, this would need attention.

## Reflection
I enjoyed composing this project. Both working in the existing Wikipedia app as setting up something entirely new in iOS was very refreshing. It contained a lot of moments where I recognized the syntax I always used for the native codebase of my own app (especially the resemblence of CoreData in SwiftData), and some moments where I crunched new technologies like working with Actors.

As with every project, this project contains decisions that I want to elaborate and reflect on.

### Layered packages
The packages in this project are layered 'vertically', as described above. This seemed the best fit for now, since the project does not contain a very 'broad' set of features and/or models. When a project grows, I always like to create a composition of packages where there is one layer (or a small amount of layers) in the 'bottom' that is shared by the entire application, and to then create packages for each app feature on top of that. Due to the narrow nature of this project, it did not make much sense to implement such a project structure here. 

I did consider turning the autocomplete feature into a separate package, but that would introduce an inconsistency which i disliked more than just having the entire app divided in the layers of the architecture.

### Inconsistencies in testing
When it comes to testing, I've seen a lot of tastes and ways of doing things. I always work using the Given When Then paradigm. How this is applied, differs per project team. In one project, the full rationale will be written out before the function, in the other there will only be 'Given', 'When' and 'Then' comments in a function. In LocationsRepository I applied the former, and with the other tests the latter. I'm curious what your taste is! My preference goes to the latter.

Another thing I differed in is the setup. LocationsRepositoryTests contains the - in my eyes - more tradtional approach with beforeEach and afterEach functions. The rest of the project contains tests where every function creates it's own dependencies. The latter is more familiar to me.

### Typed throws
It seems so simple, but I love this feature. This allows me to make the flow of errors that streams upwards from the data layer to the UI so much neater!

### No Macro's
I wanted to set up my own macro to make my models conform to Decodable, but ran out of time :(.

### Generic LocalLocationsService
Back when my own app was still a Swift Native project, I had set up a generic CoreData store. This contained a generic CRUD that was able to work with all my models. In addition, the Class based models I had for CoreData (NSManagedObject) had a Struct counterpart that I used throughout my the rest of my application to be sure that the data layer was separated from the rest. 

I considered doing the same thing here, since the SwiftData API is geared towards is pretty good. However, the project so far contains only one model in SwiftData, and I don't want to over engineer too much either. I chose to not do it, and whenever we want to extend this application with more features and models, we can always create a generic SwiftData CRUD service that we then put behind the existing LocalLocationsService.

### Decoupling VS 'syntactic sugar'
A new SwiftUI App comes with SwiftData baked right into it. In fact, baked a bit too much into it for my taste. The default project solders the database right onto the UI with a modifier. This does allow a completely awesome, reactive @Query property to observe the data in the store and update views accordingly. However, In my career as software developer, both employed and individual, I've had to change databases a bit too often to fall for this again.

Apple in fact is not the only one to do this. If you look at the documentation of services like FireStore or MongoDB's Atlas DeviceSync, they follow the same apprach: Provide really fancy syntax for reactive querying, but soldering their databases intro every nook and cranny of an application by doing so.

Even though I see the benefit of this approach for small applications, I developed a taste against it. It breaks the architecture I had in mind, and introduces endless amounts of pain if we ever want to switch to another database provider. And since we always design for longevity, changes are high we need to do this.

One thing I would have loved to do is create a better sort of update mechanism of the LocationsOverview than just a callback from the LocationDetailView when a modifciation was made. I don't like that bit of this project. Time got me there.

# Wikipedia
The Wikipedia app can be found here: [Wikipedia](https://github.com/joris1995/wikipedia-ios-places-mod/settings)

### Universal links or deep links?
Having a brief look at the apple-app-site-association from Wikipedia, I saw they only allow URL schemes at subdirectory /wiki/. The website also does not have a places feature like the app, which gave me the impression that Universal links were not the way to go. I carried on with a Deep Link.

### Approach
Since I wanted to focus on creating a solid app of my own, I implemented the requested feature as minimal as possible. The app was already able to open the places tab, but not a location yet.
Therefore, I chose to add location parsing to the NSUserActivity+WMFExtensions.m file. One risk I saw, is that the map can also show an article based on the deep link, but what if the user passes both an article and a location? For time's sake, I chose to not dig too deep into this, and just assume they would be able to happily go together.

I built forward on the existing logic that opened the Places tab from a deep link. I implemented a simple function that pans to the provided coordinates upon displaying the Places Tab (`showLocationOnMap`). This, however, introduced a crash! The feature worked like a breeze when the Wikipedia app was already open in the background, but doing this from a cold start caused a crash. 

To fix this, I implemented a flag in the PlacesViewController: `viewReadyForExternalMapControl`, which is false by default. As soon as the view appears, this is set to true. I then updated the `showLocationOnMap` function to only pan to a certain location when `viewReadyForExternalMapControl` is true, and to store the location in a waiting variable (`pendingInjectedLocation`) otherwise.
I finished this approach by determining a setter method on `viewReadyForExternalMapControl` that triggers the `showLocationOnMap` whenever it is set to true and there is a location waiting in the `pendingInjectedLocation`.

