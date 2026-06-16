import React, { createContext, useContext, useEffect, useState } from 'react';
import { 
    createUserWithEmailAndPassword, 
    signInWithEmailAndPassword, 
    signOut, 
    onAuthStateChanged,
    updateProfile,
    GoogleAuthProvider,
    signInWithPopup,
    EmailAuthProvider,
    linkWithCredential
} from 'firebase/auth';
import { doc, getDoc, setDoc, serverTimestamp, onSnapshot } from 'firebase/firestore';
import { auth, db } from '../lib/firebase';

const AuthContext = createContext();

export function useAuth() {
    return useContext(AuthContext);
}

export function AuthProvider({ children }) {
    const [currentUser, setCurrentUser] = useState(null);
    const [loading, setLoading] = useState(true);

    async function signup(email, password, name) {
        const userCredential = await createUserWithEmailAndPassword(auth, email, password);
        if (name) {
            await updateProfile(userCredential.user, { displayName: name });
        }
        
        const isSuperAdmin = email.trim().toLowerCase() === 'admin-ev@gmail.com';
        
        // Create user document matching flutter schema
        await setDoc(doc(db, 'users', userCredential.user.uid), {
            name: name || (isSuperAdmin ? 'Super Admin' : ''),
            email: email,
            walletBalance: isSuperAdmin ? 10000.0 : 0.0,
            createdAt: serverTimestamp(),
            role: isSuperAdmin ? 'admin' : 'user'
        });
        
        return userCredential;
    }

    async function login(email, password) {
        try {
            return await signInWithEmailAndPassword(auth, email, password);
        } catch (err) {
            // If credentials are invalid, the account may only have Google provider.
            // Try Google sign-in and link the email/password so both work in future.
            if (err.code === 'auth/invalid-credential' || err.code === 'auth/wrong-password') {
                try {
                    const provider = new GoogleAuthProvider();
                    provider.setCustomParameters({ login_hint: email });
                    const result = await signInWithPopup(auth, provider);

                    // If the Google email matches, link the password credential
                    if (result.user && result.user.email?.toLowerCase() === email.trim().toLowerCase()) {
                        try {
                            const credential = EmailAuthProvider.credential(email, password);
                            await linkWithCredential(result.user, credential);
                        } catch (linkErr) {
                            // provider-already-linked is fine — means password is already set
                            if (linkErr.code !== 'auth/provider-already-linked') {
                                console.warn('Could not link email/password provider:', linkErr.code);
                            }
                        }
                    }
                    return result;
                } catch (googleErr) {
                    // If user cancelled Google popup or emails don't match, throw original error
                    throw err;
                }
            }
            throw err;
        }
    }

    async function signInWithGoogle() {
        const provider = new GoogleAuthProvider();
        const userCredential = await signInWithPopup(auth, provider);
        
        // Check if user exists in database, if not create profile
        const docRef = doc(db, 'users', userCredential.user.uid);
        const docSnap = await getDoc(docRef);
        
        if (!docSnap.exists()) {
            const isSuperAdmin = userCredential.user.email.toLowerCase().trim() === 'admin-ev@gmail.com';
            await setDoc(docRef, {
                name: userCredential.user.displayName || '',
                email: userCredential.user.email,
                walletBalance: isSuperAdmin ? 10000.0 : 0.0,
                createdAt: serverTimestamp(),
                role: isSuperAdmin ? 'admin' : 'user'
            });
        }
        
        return userCredential;
    }

    function logout() {
        return signOut(auth);
    }

    useEffect(() => {
        let unsubscribeProfile = null;
        const unsubscribe = onAuthStateChanged(auth, async (user) => {
            if (unsubscribeProfile) {
                unsubscribeProfile();
                unsubscribeProfile = null;
            }
            if (user) {
                const docRef = doc(db, 'users', user.uid);
                const isSuperAdmin = user.email && user.email.toLowerCase().trim() === 'admin-ev@gmail.com';

                unsubscribeProfile = onSnapshot(docRef, async (docSnap) => {
                    try {
                        let profileData = docSnap.exists() ? docSnap.data() : null;
                        
                        if (isSuperAdmin) {
                            if (!profileData) {
                                profileData = {
                                    name: 'Super Admin',
                                    email: user.email,
                                    walletBalance: 10000.0,
                                    createdAt: new Date(),
                                    role: 'admin'
                                };
                                await setDoc(docRef, profileData);
                                console.log("Auto-created Firestore document for Super Admin.");
                            } else if (profileData.role !== 'admin') {
                                profileData.role = 'admin';
                                await setDoc(docRef, { role: 'admin' }, { merge: true });
                                console.log("Enforced role: 'admin' in Firestore for Super Admin.");
                            }
                        }
                        
                        if (profileData) {
                            setCurrentUser({ ...user, profile: profileData });
                        } else {
                            setCurrentUser(user);
                        }
                    } catch (error) {
                        console.error("Error processing user profile updates:", error);
                        setCurrentUser(user);
                    } finally {
                        setLoading(false);
                    }
                }, (error) => {
                    console.error("Error listening to user profile:", error);
                    setCurrentUser(user);
                    setLoading(false);
                });
            } else {
                setCurrentUser(null);
                setLoading(false);
            }
        });

        return () => {
            unsubscribe();
            if (unsubscribeProfile) unsubscribeProfile();
        };
    }, []);

    const value = {
        currentUser,
        login,
        signup,
        signInWithGoogle,
        logout
    };

    return (
        <AuthContext.Provider value={value}>
            {!loading && children}
        </AuthContext.Provider>
    );
}
