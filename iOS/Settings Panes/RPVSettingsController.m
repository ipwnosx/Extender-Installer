//
//  EESettingsController.m
//  Extender Installer
//
//  Created by Matt Clarke on 26/04/2017.
//
//

#import "RPVSettingsController.h"
#import "RPVAdvancedController.h"
#import "RPVResources.h"

@interface PSSpecifier (Private)
- (void)setButtonAction:(SEL)arg1;
@end

@implementation RPVSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    }
    
    [[self navigationItem] setTitle:@"Settings"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Reload Apple ID stuff
    [self updateSpecifiersForAppleID:[RPVResources getUsername]];
}

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [NSMutableArray array];
        
        // Create specifiers!
        [testingSpecs addObjectsFromArray:[self _appleIDSpecifiers]];
        [testingSpecs addObjectsFromArray:[self _alertSpecifiers]];
        
        _specifiers = testingSpecs;
    }
    
    return _specifiers;
}

- (NSArray*)_appleIDSpecifiers {
    NSMutableArray *loggedIn = [NSMutableArray array];
    NSMutableArray *loggedOut = [NSMutableArray array];
    
    PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@"Apple ID"];
    [group setProperty:@"Your password is only sent to Apple." forKey:@"footerText"];
    [loggedOut addObject:group];
    [loggedIn addObject:group];
    
    // Logged in
    
    NSString *title = [NSString stringWithFormat:@"Apple ID: %@", [RPVResources getUsername]];;
    _loggedInSpec = [PSSpecifier preferenceSpecifierNamed:title target:self set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
    [_loggedInSpec setProperty:@"appleid" forKey:@"key"];
    
    [loggedIn addObject:_loggedInSpec];
    
    PSSpecifier *signout = [PSSpecifier preferenceSpecifierNamed:@"Sign Out" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
    [signout setButtonAction:@selector(didClickSignOut:)];
    
    [loggedIn addObject:signout];
    
    // Logged out.
    
    PSSpecifier *signin = [PSSpecifier preferenceSpecifierNamed:@"Sign In" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
    [signin setButtonAction:@selector(didClickSignIn:)];
    
    [loggedOut addObject:signin];
    
    _loggedInAppleSpecifiers = loggedIn;
    _loggedOutAppleSpecifiers = loggedOut;

    _hasCachedUser = [RPVResources getUsername] != nil;
    return _hasCachedUser ? _loggedInAppleSpecifiers : _loggedOutAppleSpecifiers;
}

- (NSArray*)_alertSpecifiers {
    NSMutableArray *array = [NSMutableArray array];
    
    PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@"Automated Re-signing"];
    [group setProperty:@"Set how many days away from an application's expiration date a re-sign will occur." forKey:@"footerText"];
    [array addObject:group];
    
    PSSpecifier *resign = [PSSpecifier preferenceSpecifierNamed:@"Automatically Re-sign" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
    [resign setProperty:@"resign" forKey:@"key"];
    [resign setProperty:@1 forKey:@"default"];
    
    [array addObject:resign];
    
    PSSpecifier *threshold = [PSSpecifier preferenceSpecifierNamed:@"Re-sign Applications When:" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:NSClassFromString(@"PSListItemsController") cell:PSLinkListCell edit:nil];
    [threshold setProperty:@YES forKey:@"enabled"];
    [threshold setProperty:@2 forKey:@"default"];
    threshold.values = [NSArray arrayWithObjects:@1, @2, @3, @4, @5, @6, nil];
    threshold.titleDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"1 Day Left", @"2 Days Left", @"3 Days Left", @"4 Days Left", @"5 Days Left", @"6 Days Left", nil] forKeys:threshold.values];
    threshold.shortTitleDictionary = threshold.titleDictionary;
    [threshold setProperty:@"thresholdForResigning" forKey:@"key"];
    [threshold setProperty:@"For example, setting \"2 Days Left\" will cause an application to get re-signed when it is 2 days away from expiring." forKey:@"staticTextMessage"];
    
    [array addObject:threshold];
    
    PSSpecifier *group2 = [PSSpecifier groupSpecifierWithName:@"Notifications"];
    [array addObject:group2];
    
    PSSpecifier *showInfoAlerts = [PSSpecifier preferenceSpecifierNamed:@"Show Non-Urgent Alerts" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
    [showInfoAlerts setProperty:@"showNonUrgentAlerts" forKey:@"key"];
    [showInfoAlerts setProperty:@0 forKey:@"default"];
    
    [array addObject:showInfoAlerts];
    
    PSSpecifier *showDebugAlerts = [PSSpecifier preferenceSpecifierNamed:@"Show Debug Alerts" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];
    [showDebugAlerts setProperty:@"showDebugAlerts" forKey:@"key"];
    [showDebugAlerts setProperty:@0 forKey:@"default"];
    
    [array addObject:showDebugAlerts];
    
    PSSpecifier *group3 = [PSSpecifier groupSpecifierWithName:@""];
    [array addObject:group3];
    
    PSSpecifier* troubleshoot = [PSSpecifier preferenceSpecifierNamed:@"Advanced"
                                                               target:self
                                                                  set:NULL
                                                                  get:NULL
                                                               detail:[RPVAdvancedController class]
                                                                 cell:PSLinkCell
                                                                 edit:Nil];
    
    [array addObject:troubleshoot];
    
    return array;
}

- (void)updateSpecifiersForAppleID:(NSString*)username {
    BOOL hasCachedUser = [RPVResources getUsername] != nil;
    
    if (hasCachedUser == _hasCachedUser) {
        // Do nothing.
        return;
    }
    
    _hasCachedUser = hasCachedUser;
    
    // Update "Apple ID: XXX"
    NSString *title = [NSString stringWithFormat:@"Apple ID: %@", username];
    [_loggedInSpec setName:title];
    [_loggedInSpec setProperty:title forKey:@"label"];
    
    if (hasCachedUser) {
        [self removeContiguousSpecifiers:_loggedOutAppleSpecifiers animated:YES];
        [self insertContiguousSpecifiers:_loggedInAppleSpecifiers atIndex:0];
    } else {
        [self removeContiguousSpecifiers:_loggedInAppleSpecifiers animated:YES];
        [self insertContiguousSpecifiers:_loggedOutAppleSpecifiers atIndex:0];
    }
}

- (void)didClickSignOut:(id)sender {
    [RPVResources userDidRequestAccountSignOut];
    
    [self updateSpecifiersForAppleID:@""];
}

- (void)didClickSignIn:(id)sender {
    [RPVResources userDidRequestAccountSignIn];
}

- (id)readPreferenceValue:(PSSpecifier*)value {
    NSString *key = [value propertyForKey:@"key"];
    id val = [RPVResources preferenceValueForKey:key];
    
    if (!val) {
        // Defaults.
        
        if ([key isEqualToString:@"thresholdForResigning"]) {
            return [NSNumber numberWithInt:2];
        } else if ([key isEqualToString:@"showDebugAlerts"]) {
            return [NSNumber numberWithBool:NO];
        } else if ([key isEqualToString:@"showNonUrgentAlerts"]) {
            return [NSNumber numberWithBool:NO];
        } else if ([key isEqualToString:@"resign"]) {
            return [NSNumber numberWithBool:YES];
        }
        
        return nil;
    } else {
        return val;
    }
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSString *notification = specifier.properties[@"PostNotification"];
    
    [RPVResources setPreferenceValue:value forKey:key withNotification:notification];
}

@end