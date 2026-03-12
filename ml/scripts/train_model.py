import pandas as pd
import numpy as np
import os
import pickle
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score

def train_model():
    processed_dir = 'ml/data/processed'
    models_dir = 'ml/models'
    os.makedirs(models_dir, exist_ok=True)
    
    train_df = pd.read_csv(os.path.join(processed_dir, 'train.csv'))
    test_df = pd.read_csv(os.path.join(processed_dir, 'test.csv'))
    
    X_train = train_df.drop('target', axis=1)
    y_train = train_df['target']
    X_test = test_df.drop('target', axis=1)
    y_test = test_df['target']
    
    print(f"Training on {len(X_train)} samples...")
    
    # Improved RandomForest for better accuracy as per user request
    clf = RandomForestClassifier(
        n_estimators=200, 
        max_depth=20, 
        min_samples_split=2,
        min_samples_leaf=1,
        random_state=42,
        n_jobs=-1 # Speed up training
    )
    clf.fit(X_train, y_train)
    
    y_pred = clf.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    
    print(f"Model Accuracy: {acc:.4f}")
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred))
    
    # Save model
    with open(os.path.join(models_dir, 'pose_classifier.pkl'), 'wb') as f:
        pickle.dump(clf, f)
        
    print(f"Improved model saved to {os.path.join(models_dir, 'pose_classifier.pkl')}")

if __name__ == "__main__":
    train_model()
