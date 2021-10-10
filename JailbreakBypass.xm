//
//  JailbreakBypass.xm
//  tiktok-god
//  
//  Created by Tanner Bennett on 2021-10-10
//  Copyright © 2021 Tanner Bennett. All rights reserved.
//

%hook AppsFlyerUtils
+ (BOOL)isJailbrokenWithSkipAdvancedJailbreakValidation:(BOOL)arg1 {
    return NO;
}
%end

%hook BDADeviceHelper
+ (BOOL)isJailBroken {
    return NO;
}
%end

%hook BDInstallNetworkUtility
+ (BOOL)isJailBroken {
    return NO;
}
%end

%hook IESLiveDeviceInfo
+ (BOOL)isJailBroken {
    return NO;
}
%end

%hook PIPOStoreKitHelper
+ (BOOL)isJailBroken {
    return NO;
}
%end

%hook TTAdSplashDeviceHelper
+ (BOOL)isJailBroken {
    return NO;
}
%end

%hook TTInstallUtil
+ (BOOL)isJailBroken {
    return NO;
}
%end

%hook PIPOIAPStoreManager
- (BOOL)_pipo_isJailBrokenDeviceWithProductID:(id)arg1 orderID:(id)arg2 {
    return NO;
}
%end

%hook UIDevice
+ (BOOL)btd_isJailBroken {
    return NO;
}
%end
