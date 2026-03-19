#include <stdio.h>
#include <assert.h>
#include <sys/stat.h>

char* read_file_data(size_t* bytes_in_file);
void write_file(char* text_buf, size_t bytes_in_file);

const int patch_addr = 0x35;
const int replace = 0x47;

int main()
{
	size_t bytes_in_file = 0;
	char* text_buf = read_file_data(&bytes_in_file);

	text_buf[patch_addr] = replace;
	
	write_file(text_buf, bytes_in_file);

	free(text_buf);

	return 0;
}


// Gets file data in buffer

char* read_file_data(size_t* bytes_in_file)
{
	FILE* file_ptr = fopen("PSW2.COM", "r");
	assert(file_ptr);

	struct stat file_info = {};
	fstat(fileno(file_ptr), &file_info);

	*bytes_in_file = (size_t) file_info.st_size;

	char* text_buf = (char*) calloc(*bytes_in_file + 1, sizeof(text_buf[0]));
	assert(text_buf);

	size_t bytes_read = fread(text_buf, sizeof(text_buf[0]), 
							*bytes_in_file, file_ptr);

	printf("bytes in file: %zu\n", bytes_read);
	printf("bytes read: %zu\n", bytes_read);
	assert(bytes_read == *bytes_in_file);

	fclose(file_ptr);
	return text_buf;
}	


// Creates patched file and saves changes

void write_file(char* text_buf, size_t bytes_in_file)
{
	FILE* output_file = fopen("patch.com", "w");
	size_t bytes_written = fwrite(text_buf, sizeof(text_buf[0]), 
						bytes_in_file, output_file);
	assert(bytes_in_file == bytes_written);
	fclose(output_file);
}
