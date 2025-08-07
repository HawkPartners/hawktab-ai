'use client';

import { useState, useRef } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CheckCircle, Upload, X } from 'lucide-react';

interface FileUploadProps {
  title: string;
  description: string;
  acceptedTypes: string;
  fileExtensions: string[];
  onFileSelect: (file: File | null) => void;
  selectedFile: File | null;
}

export default function FileUpload({
  title,
  description,
  acceptedTypes,
  fileExtensions,
  onFileSelect,
  selectedFile,
}: FileUploadProps) {
  const [isDragOver, setIsDragOver] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
    
    const files = Array.from(e.dataTransfer.files);
    if (files.length > 0) {
      const file = files[0];
      if (validateFile(file)) {
        onFileSelect(file);
      }
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files && files.length > 0) {
      const file = files[0];
      if (validateFile(file)) {
        onFileSelect(file);
      }
    }
  };

  const validateFile = (file: File): boolean => {
    const fileName = file.name.toLowerCase();
    return fileExtensions.some(ext => fileName.endsWith(ext.toLowerCase()));
  };

  const handleClick = () => {
    fileInputRef.current?.click();
  };

  const handleRemoveFile = (e: React.MouseEvent) => {
    e.stopPropagation();
    onFileSelect(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <Card className="w-full max-w-sm mx-auto">
      <CardHeader>
        <CardTitle className="text-lg">{title}</CardTitle>
        <CardDescription>{description}</CardDescription>
      </CardHeader>
      <CardContent>
        <div
          className={`
            border-2 border-dashed rounded-lg p-6 text-center cursor-pointer transition-all duration-200
            ${isDragOver
              ? 'border-primary bg-primary/10 scale-105'
              : selectedFile
              ? 'border-green-500 bg-green-50 dark:bg-green-950'
              : 'border-muted-foreground/25 hover:border-muted-foreground/50'
            }
          `}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
          onClick={handleClick}
        >
        <input
          ref={fileInputRef}
          type="file"
          accept={acceptedTypes}
          onChange={handleFileChange}
          className="hidden"
        />
        
        {selectedFile ? (
          <div className="space-y-4">
            <div className="flex items-center justify-center w-12 h-12 mx-auto bg-green-100 dark:bg-green-900 rounded-full">
              <CheckCircle className="w-6 h-6 text-green-600 dark:text-green-400" />
            </div>
            <div>
              <p className="text-sm font-medium text-foreground">
                {selectedFile.name}
              </p>
              <Badge variant="secondary" className="mt-1">
                {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
              </Badge>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={handleRemoveFile}
              className="text-destructive hover:text-destructive"
            >
              <X className="w-4 h-4 mr-1" />
              Remove file
            </Button>
          </div>
        ) : (
          <div className="space-y-3">
            <div className="flex items-center justify-center w-12 h-12 mx-auto bg-muted rounded-full">
              <Upload className="w-6 h-6 text-muted-foreground" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">
                <span className="font-medium">Click to upload</span> or drag and drop
              </p>
              <Badge variant="outline" className="mt-2">
                {fileExtensions.join(', ')}
              </Badge>
            </div>
          </div>
        )}
        </div>
      </CardContent>
    </Card>
  );
}